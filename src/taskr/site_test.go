package main

import (
	"strings"
	"testing"
)

func TestRenderMarkerMarkdownKeepsWrappedListItemsTogether(t *testing.T) {
	got := renderMarkerMarkdown("- First line\n  continues here.\n- Second item.\n")
	want := "<ul><li>First line continues here.</li><li>Second item.</li></ul>"
	if got != want {
		t.Fatalf("rendered Markdown = %q, want %q", got, want)
	}
}

func TestRenderMarkerMarkdownLinkifiesPlainURLsButNotCode(t *testing.T) {
	got := renderMarkerMarkdown("Visit https://example.com and `https://example.invalid`.\n")
	if !strings.Contains(got, `href="https://example.com" target="_blank"`) {
		t.Fatalf("plain URL was not linked: %s", got)
	}
	if !strings.Contains(got, `<code>https://example.invalid</code>`) {
		t.Fatalf("inline code was not preserved: %s", got)
	}
	if strings.Contains(got, `href="https://example.invalid"`) {
		t.Fatalf("inline code URL was linked: %s", got)
	}
}
