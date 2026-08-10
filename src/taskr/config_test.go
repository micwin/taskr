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
