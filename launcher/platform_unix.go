//go:build !windows

package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"syscall"
)

func sysProcAttr() *syscall.SysProcAttr {
	return &syscall.SysProcAttr{}
}

// Unix terminallerinde ANSI renk zaten desteklenir.
func enableVirtualTerminal() {}

// findPHP: macOS (Homebrew) ve Linux yaygın konumlarını tarar.
func findPHP() string {
	candidates := []string{
		"/opt/homebrew/bin/php", // macOS Apple Silicon
		"/usr/local/bin/php",   // macOS Intel / Linux
		"/usr/bin/php",
	}
	for _, p := range candidates {
		if _, err := os.Stat(p); err == nil {
			return p
		}
	}
	if p, err := exec.LookPath("php"); err == nil {
		return p
	}
	return "php"
}

// findMySQLManager: Unix'te WAMP yoktur; MySQL servis olarak çalışır.
// Ana program MySQL portunu kontrol eder, bulamazsa uyarır.
func findMySQLManager() string {
	return ""
}

// findFlutter: macOS ve Linux yaygın konumlarını tarar.
func findFlutter() string {
	home, _ := os.UserHomeDir()
	candidates := []string{
		filepath.Join(home, "flutter", "bin", "flutter"),
		filepath.Join(home, "snap", "flutter", "common", "flutter", "bin", "flutter"),
		"/opt/homebrew/bin/flutter",
		"/usr/local/bin/flutter",
		"/snap/bin/flutter",
	}
	for _, p := range candidates {
		if _, err := os.Stat(p); err == nil {
			return p
		}
	}
	if p, err := exec.LookPath("flutter"); err == nil {
		return p
	}
	return "flutter"
}

// findADB: ANDROID_HOME / ANDROID_SDK_ROOT env değişkenleri
// ve macOS/Linux varsayılan SDK konumlarını tarar.
func findADB() string {
	for _, env := range []string{"ANDROID_HOME", "ANDROID_SDK_ROOT"} {
		if sdk := os.Getenv(env); sdk != "" {
			p := filepath.Join(sdk, "platform-tools", "adb")
			if _, err := os.Stat(p); err == nil {
				return p
			}
		}
	}

	home, _ := os.UserHomeDir()
	candidates := []string{
		filepath.Join(home, "Android", "Sdk", "platform-tools", "adb"),           // Linux
		filepath.Join(home, "Library", "Android", "sdk", "platform-tools", "adb"), // macOS
	}
	for _, p := range candidates {
		if _, err := os.Stat(p); err == nil {
			return p
		}
	}
	if p, err := exec.LookPath("adb"); err == nil {
		return p
	}
	return "adb"
}
