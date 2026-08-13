package main

import (
	"encoding/json"
	"fmt"
	"html"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

type siteItem struct {
	ID        string `json:"id"`
	Slug      string `json:"slug"`
	Title     string `json:"title"`
	Type      string `json:"type"`
	Status    string `json:"status"`
	Priority  string `json:"priority,omitempty"`
	Milestone string `json:"milestone,omitempty"`
	URL       string `json:"url"`
}

type markerSection struct {
	Title string
	Body  string
}

var plainURLPattern = regexp.MustCompile(`(?i)(https?://[^\s<>]+|www\.[^\s<>]+)`)

func generateSite(t *tree, now time.Time) (string, string, error) {
	target, ok := t.Config.siteDirectory(t.Root)
	if !ok {
		return "", "", exitError{code: 2, msg: "site is not initialized; run taskr site init <site-directory>"}
	}
	if _, err := os.Lstat(target); err != nil {
		if os.IsNotExist(err) {
			return "", "", exitError{code: 2, msg: fmt.Sprintf("configured site directory is missing: %s; run taskr site init", target)}
		}
		return "", "", err
	}
	if err := validateSiteMarker(target); err != nil {
		return "", "", err
	}

	parent := filepath.Dir(target)
	stage, err := os.MkdirTemp(parent, ".taskr-site-generate-*")
	if err != nil {
		return "", "", fmt.Errorf("create site staging directory: %w", err)
	}
	defer os.RemoveAll(stage)
	generatedAt := now.UTC().Truncate(time.Second).Format(time.RFC3339)
	if err := renderSite(stage, t, generatedAt); err != nil {
		return "", "", err
	}
	if err := replaceGeneratedSite(target, stage); err != nil {
		return "", "", err
	}
	return filepath.Join(target, "index.html"), generatedAt, nil
}

func renderSite(output string, t *tree, generatedAt string) error {
	for _, directory := range []string{"assets", "items"} {
		if err := os.MkdirAll(filepath.Join(output, directory), 0o755); err != nil {
			return fmt.Errorf("create generated site directory: %w", err)
		}
	}
	if err := os.WriteFile(filepath.Join(output, siteMarkerName), []byte(siteMarkerContent), 0o644); err != nil {
		return err
	}

	items := append([]*item(nil), t.Items...)
	sortItems(items)
	siteItems := make([]siteItem, 0, len(items))
	for _, it := range items {
		siteItems = append(siteItems, newSiteItem(it))
		page, err := renderItemPage(t, it, generatedAt)
		if err != nil {
			return err
		}
		if err := os.WriteFile(filepath.Join(output, "items", siteItemFilename(it)), []byte(page), 0o644); err != nil {
			return err
		}
	}

	data, err := json.Marshal(siteItems)
	if err != nil {
		return err
	}
	if err := os.WriteFile(filepath.Join(output, "assets", "items.js"), append([]byte("window.TASKR_ITEMS = "), append(data, []byte(";\n")...)...), 0o644); err != nil {
		return err
	}
	files := map[string]string{
		filepath.Join("assets", "site.js"):  siteJavaScript,
		filepath.Join("assets", "site.css"): siteCSS,
		"index.html":                        renderIndexPage(t, items, generatedAt),
		"results.html":                      renderResultsPage(t, generatedAt),
	}
	for path, content := range files {
		if err := os.WriteFile(filepath.Join(output, path), []byte(content), 0o644); err != nil {
			return err
		}
	}
	return nil
}

func replaceGeneratedSite(target, stage string) error {
	backup := target + ".taskr-backup"
	if _, err := os.Lstat(backup); err == nil {
		return fmt.Errorf("site backup path already exists: %s", backup)
	}
	if err := os.Rename(target, backup); err != nil {
		return fmt.Errorf("move existing site output: %w", err)
	}
	if err := os.Rename(stage, target); err != nil {
		_ = os.Rename(backup, target)
		return fmt.Errorf("activate generated site: %w", err)
	}
	if err := os.RemoveAll(backup); err != nil {
		return fmt.Errorf("remove replaced site output: %w", err)
	}
	return nil
}

func newSiteItem(it *item) siteItem {
	milestone := it
	for milestone != nil && milestone.Type != "milestone" {
		milestone = milestone.Parent
	}
	milestoneID := ""
	if milestone != nil {
		milestoneID = milestone.IDText
	}
	return siteItem{
		ID: it.IDText, Slug: it.Slug, Title: it.Title, Type: it.Type,
		Status: it.Status, Priority: it.Priority, Milestone: milestoneID,
		URL: "items/" + siteItemFilename(it),
	}
}

func siteItemFilename(it *item) string {
	return it.IDText + "-" + it.Slug + ".html"
}

func renderIndexPage(t *tree, items []*item, generatedAt string) string {
	project := filepath.Base(t.Root)
	var content strings.Builder
	fmt.Fprintf(&content, `<header class="page-header"><div><p class="eyebrow">Taskr project</p><h1>%s</h1><p class="generated">Generated <time datetime="%s">%s</time></p></div></header>`, html.EscapeString(project), generatedAt, generatedAt)
	content.WriteString(`<form class="search" action="results.html" method="get"><label for="site-search">Search items</label><div class="search-row"><input id="site-search" type="search" name="q" placeholder="ID, slug, or title" required><button type="submit">Search</button></div></form>`)
	content.WriteString(`<section><h2>Project status</h2>`)
	content.WriteString(renderStatusLinks(items, ""))
	content.WriteString(`</section><section><h2>Milestones</h2>`)
	for _, milestone := range items {
		if milestone.Type != "milestone" {
			continue
		}
		fmt.Fprintf(&content, `<article class="milestone"><h3><a href="items/%s">Milestone: %s</a></h3><p class="meta"><span>%s</span><span>%s</span></p>`, siteItemFilename(milestone), html.EscapeString(milestone.Title), html.EscapeString(milestone.IDText), html.EscapeString(milestone.Slug))
		var descendants []*item
		for _, candidate := range items {
			if candidate != milestone && itemMilestone(candidate) == milestone {
				descendants = append(descendants, candidate)
			}
		}
		content.WriteString(renderStatusLinks(descendants, milestone.IDText))
		content.WriteString(`<div class="item-list">`)
		for _, child := range milestone.Children {
			renderIndexItem(&content, child, 0)
		}
		content.WriteString(`</div></article>`)
	}
	content.WriteString(`</section>`)
	return siteDocument(project+" - Taskr", "", content.String(), true)
}

func renderStatusLinks(items []*item, milestone string) string {
	counts := map[string]int{}
	for _, it := range items {
		counts[it.Status]++
	}
	var b strings.Builder
	b.WriteString(`<div class="status-grid">`)
	for _, status := range statuses {
		if counts[status] == 0 {
			continue
		}
		query := "status=" + status
		if milestone != "" {
			query = "milestone=" + milestone + "&amp;" + query
		}
		fmt.Fprintf(&b, `<a class="status" href="results.html?%s"><strong>%d</strong><span>%s</span></a>`, query, counts[status], html.EscapeString(status))
	}
	b.WriteString(`</div>`)
	return b.String()
}

func renderIndexItem(b *strings.Builder, it *item, depth int) {
	fmt.Fprintf(b, `<div class="item-row" style="--depth:%d"><a class="item-id" href="items/%s">%s</a><a href="items/%s">%s</a><span class="item-slug">%s</span><span class="badge">%s</span></div>`, depth, siteItemFilename(it), html.EscapeString(it.IDText), siteItemFilename(it), html.EscapeString(it.Title), html.EscapeString(it.Slug), html.EscapeString(it.Status))
	for _, child := range it.Children {
		renderIndexItem(b, child, depth+1)
	}
}

func itemMilestone(it *item) *item {
	for it != nil && it.Type != "milestone" {
		it = it.Parent
	}
	return it
}

func renderResultsPage(t *tree, generatedAt string) string {
	content := `<header class="page-header compact"><div><p class="eyebrow">Taskr results</p><h1 id="results-title">Matching items</h1><p id="results-summary" aria-live="polite"></p></div><a href="index.html">Project overview</a></header><main><div class="table-wrap"><table id="result-table"><thead><tr><th>ID</th><th>Title</th><th>Slug</th><th>Type</th><th>Status</th></tr></thead><tbody></tbody></table><p id="empty-results" hidden>No matching items.</p></div><nav class="pager" aria-label="Result pages"><button id="previous-page" type="button">Previous</button><span id="page-status"></span><button id="next-page" type="button">Next</button></nav></main>`
	return siteDocument(filepath.Base(t.Root)+" results - Taskr", "", content, true)
}

func renderItemPage(t *tree, it *item, generatedAt string) (string, error) {
	content, err := os.ReadFile(it.MarkerPath)
	if err != nil {
		return "", err
	}
	sections, err := parseMarkerSections(string(content))
	if err != nil {
		return "", fmt.Errorf("render %s: %w", it.MarkerPath, err)
	}
	var body strings.Builder
	fmt.Fprintf(&body, `<header class="page-header compact"><div><p class="eyebrow">%s <span>%s</span></p><div class="title-row"><a id="previous-result" class="result-nav" hidden aria-label="Previous result">&lt;</a><h1>%s</h1><a id="next-result" class="result-nav" hidden aria-label="Next result">&gt;</a></div><p class="meta"><span>%s</span><span>%s</span><span>%s</span></p></div><a href="../index.html">Project overview</a></header>`, html.EscapeString(it.Type), html.EscapeString(it.IDText), html.EscapeString(it.Title), html.EscapeString(it.Slug), html.EscapeString(it.Status), html.EscapeString(it.Priority))
	body.WriteString(`<main class="ticket" data-result-context><section class="metadata"><h2>Metadata</h2><dl>`)
	metadata := [][2]string{{"ID", it.IDText}, {"Type", it.Type}, {"Slug", it.Slug}, {"Status", it.Status}, {"Priority", it.Priority}, {"Created", it.CreatedAt}, {"Updated", it.UpdatedAt}}
	for _, entry := range metadata {
		if entry[1] != "" {
			fmt.Fprintf(&body, `<dt>%s</dt><dd>%s</dd>`, entry[0], html.EscapeString(entry[1]))
		}
	}
	body.WriteString(`</dl></section>`)
	for _, section := range sections {
		fmt.Fprintf(&body, `<details open><summary>%s</summary><div class="markdown">%s</div></details>`, html.EscapeString(section.Title), renderMarkerMarkdown(section.Body))
	}
	body.WriteString(`</main>`)
	return siteDocument(it.Title+" - Taskr", "../", body.String(), true), nil
}

func parseMarkerSections(marker string) ([]markerSection, error) {
	parts := strings.Split(marker, "\n")
	if len(parts) == 0 || strings.TrimSpace(parts[0]) != "---" {
		return nil, fmt.Errorf("missing frontmatter")
	}
	index := 1
	for index < len(parts) && strings.TrimSpace(parts[index]) != "---" {
		index++
	}
	if index == len(parts) {
		return nil, fmt.Errorf("unterminated frontmatter")
	}
	var sections []markerSection
	var current *markerSection
	for _, line := range parts[index+1:] {
		if strings.HasPrefix(line, "# ") {
			sections = append(sections, markerSection{Title: strings.TrimSpace(strings.TrimPrefix(line, "# "))})
			current = &sections[len(sections)-1]
			continue
		}
		if current != nil {
			current.Body += line + "\n"
		}
	}
	if len(sections) == 0 {
		return nil, fmt.Errorf("missing Markdown sections")
	}
	return sections, nil
}

func renderMarkerMarkdown(source string) string {
	lines := strings.Split(strings.TrimSpace(source), "\n")
	var b strings.Builder
	var paragraph []string
	var listItems []string
	flushParagraph := func() {
		if len(paragraph) > 0 {
			fmt.Fprintf(&b, "<p>%s</p>", renderInlineMarkdown(strings.Join(paragraph, " ")))
			paragraph = nil
		}
	}
	flushList := func() {
		if len(listItems) > 0 {
			b.WriteString("<ul>")
			for _, item := range listItems {
				fmt.Fprintf(&b, "<li>%s</li>", renderInlineMarkdown(item))
			}
			b.WriteString("</ul>")
			listItems = nil
		}
	}
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "- ") {
			flushParagraph()
			listItems = append(listItems, strings.TrimSpace(strings.TrimPrefix(trimmed, "- ")))
			continue
		}
		if trimmed == "" {
			flushParagraph()
			flushList()
			continue
		}
		if strings.HasPrefix(trimmed, "## ") {
			flushParagraph()
			flushList()
			fmt.Fprintf(&b, "<h3>%s</h3>", renderInlineMarkdown(strings.TrimPrefix(trimmed, "## ")))
		} else if len(listItems) > 0 {
			listItems[len(listItems)-1] += " " + trimmed
		} else {
			paragraph = append(paragraph, trimmed)
		}
	}
	flushParagraph()
	flushList()
	return b.String()
}

func renderInlineMarkdown(text string) string {
	parts := strings.Split(text, "`")
	var b strings.Builder
	for index, part := range parts {
		if index%2 == 1 {
			fmt.Fprintf(&b, "<code>%s</code>", html.EscapeString(part))
		} else {
			b.WriteString(linkifyText(part))
		}
	}
	return b.String()
}

func linkifyText(text string) string {
	indices := plainURLPattern.FindAllStringIndex(text, -1)
	if len(indices) == 0 {
		return html.EscapeString(text)
	}
	var b strings.Builder
	last := 0
	for _, index := range indices {
		b.WriteString(html.EscapeString(text[last:index[0]]))
		label := strings.TrimRight(text[index[0]:index[1]], ".,;:!?)")
		href := label
		if strings.HasPrefix(strings.ToLower(href), "www.") {
			href = "https://" + href
		}
		fmt.Fprintf(&b, `<a href="%s" target="_blank" rel="noopener noreferrer">%s</a>`, html.EscapeString(href), html.EscapeString(label))
		b.WriteString(html.EscapeString(text[index[0]+len(label) : index[1]]))
		last = index[1]
	}
	b.WriteString(html.EscapeString(text[last:]))
	return b.String()
}

func siteDocument(title, assetPrefix, content string, scripts bool) string {
	var scriptTags string
	if scripts {
		scriptTags = fmt.Sprintf(`<script src="%sassets/items.js"></script><script src="%sassets/site.js"></script>`, assetPrefix, assetPrefix)
	}
	return fmt.Sprintf(`<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>%s</title><link rel="stylesheet" href="%sassets/site.css"></head><body>%s%s</body></html>`, html.EscapeString(title), assetPrefix, content, scriptTags)
}

const siteCSS = `:root{color-scheme:light;--ink:#17202a;--muted:#66717d;--line:#d9dee3;--paper:#fff;--wash:#f4f6f7;--accent:#176b5b;--warm:#a44c22;font-family:Inter,ui-sans-serif,system-ui,sans-serif}*{box-sizing:border-box}body{margin:0;background:var(--wash);color:var(--ink);letter-spacing:0}.page-header,main,body>section,body>form{max-width:1120px;margin:0 auto;padding:24px}.page-header{display:flex;align-items:end;justify-content:space-between;border-bottom:1px solid var(--line);background:var(--paper)}.page-header.compact{align-items:center}.eyebrow{margin:0;color:var(--accent);font-weight:700;text-transform:uppercase;font-size:.75rem}.page-header h1{margin:4px 0 0;font-size:2rem}.generated,.meta{display:flex;gap:12px;color:var(--muted);font-size:.875rem}.search{background:var(--paper)}.search label{display:block;font-weight:700;margin-bottom:8px}.search-row{display:flex;gap:8px}.search input{min-width:0;flex:1;padding:11px;border:1px solid #9da7b0}.search button,.pager button{padding:10px 16px;border:0;background:var(--accent);color:#fff;cursor:pointer}section{background:var(--paper)}.status-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(120px,1fr));gap:8px}.status{display:flex;justify-content:space-between;padding:12px;border-left:4px solid var(--accent);background:var(--wash);color:inherit;text-decoration:none}.milestone{border-top:1px solid var(--line);padding:18px 0}.milestone h3{margin:0}.item-list{margin-top:12px}.item-row{display:grid;grid-template-columns:60px minmax(180px,1fr) minmax(100px,220px) 100px;gap:10px;padding:8px 8px 8px calc(8px + var(--depth)*24px);border-top:1px solid var(--line);align-items:center}.item-id{font-family:ui-monospace,monospace}.item-slug{color:var(--muted);overflow-wrap:anywhere}.badge{font-size:.75rem;text-transform:uppercase;color:var(--warm)}a{color:var(--accent)}.table-wrap{overflow:auto;background:var(--paper)}table{width:100%;border-collapse:collapse}th,td{text-align:left;padding:10px;border-bottom:1px solid var(--line)}.pager{display:flex;align-items:center;justify-content:center;gap:16px;margin-top:16px}.title-row{display:flex;align-items:center;gap:10px}.result-nav{font-size:1.5rem;text-decoration:none}.ticket details,.metadata{max-width:900px;margin:12px auto;background:var(--paper);border:1px solid var(--line)}.ticket summary{padding:14px;font-weight:700;cursor:pointer}.markdown{padding:0 18px 16px;line-height:1.6}.metadata{padding:16px}.metadata dl{display:grid;grid-template-columns:120px 1fr;gap:6px}.metadata dt{font-weight:700}.metadata dd{margin:0}@media(max-width:680px){.page-header{align-items:flex-start;gap:16px;flex-direction:column}.item-row{grid-template-columns:48px 1fr}.item-slug,.badge{grid-column:2}.search-row{flex-direction:column}}`

const siteJavaScript = `(() => {
  const items = window.TASKR_ITEMS || [];
  const params = new URLSearchParams(window.location.search);
  const pageSize = 25;
  const normalizedID = value => value.replace(/^0+/, '') || '0';
  const matches = item => {
    const query = (params.get('q') || '').trim().toLowerCase();
    const status = params.get('status') || '';
    const milestone = params.get('milestone') || '';
    if (status && item.status !== status) return false;
    if (milestone && item.milestone !== milestone) return false;
    if (!query) return true;
    return normalizedID(item.id) === normalizedID(query) || item.slug.toLowerCase().includes(query) || item.title.toLowerCase().includes(query);
  };
  const resultItems = items.filter(matches);
  const table = document.querySelector('#result-table');
  if (table) {
    if (params.get('q') && resultItems.length === 1) {
      const context = params.toString();
      window.location.replace(resultItems[0].url + '?context=' + encodeURIComponent(context));
      return;
    }
    let page = Math.max(1, Number(params.get('page') || 1));
    const pages = Math.max(1, Math.ceil(resultItems.length / pageSize));
    page = Math.min(page, pages);
    const body = table.querySelector('tbody');
    resultItems.slice((page - 1) * pageSize, page * pageSize).forEach(item => {
      const row = document.createElement('tr');
      const context = params.toString();
      const href = item.url + '?context=' + encodeURIComponent(context);
      [item.id, item.title, item.slug].forEach(value => {
        const cell = document.createElement('td');
        const link = document.createElement('a');
        link.href = href; link.textContent = value;
        cell.appendChild(link); row.appendChild(cell);
      });
      [item.type, item.status].forEach(value => {
        const cell = document.createElement('td');
        cell.textContent = value; row.appendChild(cell);
      });
      body.appendChild(row);
    });
    document.querySelector('#empty-results').hidden = resultItems.length !== 0;
    document.querySelector('#results-summary').textContent = resultItems.length + ' matching items';
    document.querySelector('#page-status').textContent = 'Page ' + page + ' of ' + pages;
    const setPage = next => { params.set('page', String(next)); window.location.search = params.toString(); };
    const previous = document.querySelector('#previous-page');
    const next = document.querySelector('#next-page');
    previous.disabled = page <= 1; next.disabled = page >= pages;
    previous.addEventListener('click', () => setPage(page - 1));
    next.addEventListener('click', () => setPage(page + 1));
  }
  const ticket = document.querySelector('[data-result-context]');
  if (ticket && params.has('context')) {
    const context = new URLSearchParams(params.get('context'));
    const ordered = items.filter(item => {
      const query = (context.get('q') || '').trim().toLowerCase();
      const status = context.get('status') || '';
      const milestone = context.get('milestone') || '';
      return (!status || item.status === status) && (!milestone || item.milestone === milestone) && (!query || normalizedID(item.id) === normalizedID(query) || item.slug.toLowerCase().includes(query) || item.title.toLowerCase().includes(query));
    });
    const currentName = decodeURIComponent(window.location.pathname.split('/').pop()).replace(/\.html$/, '');
    const index = ordered.findIndex(item => item.id + '-' + item.slug === currentName);
    const bind = (id, item) => { if (!item) return; const link = document.querySelector(id); link.href = item.url.replace('items/', '') + '?context=' + encodeURIComponent(context.toString()); link.hidden = false; };
    bind('#previous-result', ordered[index - 1]);
    bind('#next-result', ordered[index + 1]);
  }
})();`
