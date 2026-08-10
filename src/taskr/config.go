package main

import (
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/pelletier/go-toml/v2"
)

const projectConfigName = "taskr.toml"

type projectConfig struct {
	Site *siteProjectConfig `toml:"site"`
}

type siteProjectConfig struct {
	Directory string `toml:"directory"`
}

func loadProjectConfig(root string) (projectConfig, error) {
	path := filepath.Join(root, projectConfigName)
	f, err := os.Open(path)
	if errors.Is(err, fs.ErrNotExist) {
		return projectConfig{}, nil
	}
	if err != nil {
		return projectConfig{}, exitError{code: 2, msg: fmt.Sprintf("%s: cannot read project configuration: %v", path, err)}
	}
	defer f.Close()

	var config projectConfig
	decoder := toml.NewDecoder(f)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&config); err != nil {
		return projectConfig{}, exitError{code: 2, msg: fmt.Sprintf("%s: invalid project configuration: %s", path, projectConfigError(err))}
	}
	if config.Site != nil {
		if strings.TrimSpace(config.Site.Directory) == "" {
			return projectConfig{}, exitError{code: 2, msg: fmt.Sprintf("%s: site.directory must not be empty", path)}
		}
		if strings.ContainsRune(config.Site.Directory, '\x00') {
			return projectConfig{}, exitError{code: 2, msg: fmt.Sprintf("%s: site.directory contains a NUL byte", path)}
		}
	}
	return config, nil
}

func projectConfigError(err error) string {
	var unknown *toml.StrictMissingError
	if errors.As(err, &unknown) {
		keys := make([]string, 0, len(unknown.Errors))
		for i := range unknown.Errors {
			keys = append(keys, strings.Join(unknown.Errors[i].Key(), "."))
		}
		sort.Strings(keys)
		return fmt.Sprintf("unknown project configuration key %q", strings.Join(keys, ", "))
	}
	return err.Error()
}

func (config projectConfig) siteDirectory(root string) (string, bool) {
	if config.Site == nil {
		return "", false
	}
	directory := config.Site.Directory
	if !filepath.IsAbs(directory) {
		directory = filepath.Join(root, directory)
	}
	return filepath.Clean(directory), true
}
