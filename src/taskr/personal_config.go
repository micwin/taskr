package main

import (
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"

	"gopkg.in/yaml.v3"
)

type personalConfig struct {
	Statuses   []string `yaml:"statuses"`
	Editor     string   `yaml:"editor"`
	ArchiveDir string   `yaml:"archive_dir"`
	Browser    string   `yaml:"browser"`
	Pager      string   `yaml:"pager"`
}

func loadPersonalConfig(explicit string) (personalConfig, error) {
	path, required, err := personalConfigPath(explicit)
	if err != nil {
		return personalConfig{}, err
	}
	if path == "" {
		return personalConfig{}, nil
	}
	f, err := os.Open(path)
	if errors.Is(err, fs.ErrNotExist) && !required {
		return personalConfig{}, nil
	}
	if err != nil {
		return personalConfig{}, exitError{code: 2, msg: fmt.Sprintf("cannot read personal configuration %s: %v", path, err)}
	}
	defer f.Close()

	var config personalConfig
	decoder := yaml.NewDecoder(f)
	decoder.KnownFields(true)
	if err := decoder.Decode(&config); err != nil {
		return personalConfig{}, exitError{code: 2, msg: fmt.Sprintf("invalid personal configuration %s: %v", path, err)}
	}
	config.Browser = strings.TrimSpace(config.Browser)
	return config, nil
}

func personalConfigPath(explicit string) (string, bool, error) {
	if explicit != "" {
		return explicit, true, nil
	}
	if path := os.Getenv("TASKR_CONFIG_FILE"); path != "" {
		return path, true, nil
	}
	base := os.Getenv("XDG_CONFIG_HOME")
	if base == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			return "", false, err
		}
		base = filepath.Join(home, ".config")
	}
	return filepath.Join(base, "taskr", "config.yaml"), false, nil
}
