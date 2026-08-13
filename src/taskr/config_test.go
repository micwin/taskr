package main

import (
	"os"
	"path/filepath"
	"testing"
)

func TestProjectConfigResolvesSiteDirectoryFromRoot(t *testing.T) {
	root := t.TempDir()
	configPath := filepath.Join(root, "taskr.toml")
	if err := os.WriteFile(configPath, []byte("[site]\ndirectory = \"../site\"\n"), 0o644); err != nil {
		t.Fatal(err)
	}

	config, err := loadProjectConfig(root)
	if err != nil {
		t.Fatal(err)
	}
	got, ok := config.siteDirectory(root)
	if !ok {
		t.Fatal("expected configured site directory")
	}
	want := filepath.Clean(filepath.Join(root, "../site"))
	if got != want {
		t.Fatalf("site directory = %q, want %q", got, want)
	}
}

func TestProjectConfigWithoutFileHasNoSiteDirectory(t *testing.T) {
	root := t.TempDir()
	config, err := loadProjectConfig(root)
	if err != nil {
		t.Fatal(err)
	}
	if _, ok := config.siteDirectory(root); ok {
		t.Fatal("missing taskr.toml unexpectedly configured a site directory")
	}
}

func TestProjectConfigCreateStatusPrecedence(t *testing.T) {
	config := projectConfig{Defaults: &defaultsProjectConfig{
		CreateStatus:    "designing",
		MilestoneStatus: "blocked",
		TaskStatus:      "developing",
	}}

	tests := []struct {
		name     string
		itemType string
		explicit string
		want     string
	}{
		{name: "explicit", itemType: "task", explicit: "reviewing", want: "reviewing"},
		{name: "type", itemType: "task", want: "developing"},
		{name: "other type", itemType: "milestone", want: "blocked"},
		{name: "common", itemType: "subtask", want: "designing"},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if got := config.initialCreateStatus(test.itemType, test.explicit); got != test.want {
				t.Fatalf("initialCreateStatus() = %q, want %q", got, test.want)
			}
		})
	}
}

func TestProjectConfigRejectsInvalidCreateDefault(t *testing.T) {
	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, "taskr.toml"), []byte("[defaults]\ncreate_status = \"done\"\n"), 0o644); err != nil {
		t.Fatal(err)
	}

	if _, err := loadProjectConfig(root); err == nil {
		t.Fatal("expected closed create default to fail")
	}
}
