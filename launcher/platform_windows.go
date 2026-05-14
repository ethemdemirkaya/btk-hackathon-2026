//go:build windows

package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"syscall"

	"golang.org/x/sys/windows"
)

func sysProcAttr() *syscall.SysProcAttr {
	return &syscall.SysProcAttr{
		CreationFlags: syscall.CREATE_NEW_PROCESS_GROUP,
		HideWindow:    false,
	}
}

func enableVirtualTerminal() {
	stdout := windows.Handle(uintptr(syscall.Stdout))
	var mode uint32
	windows.GetConsoleMode(stdout, &mode)
	windows.SetConsoleMode(stdout, mode|windows.ENABLE_VIRTUAL_TERMINAL_PROCESSING)
}

// findPHP: WAMP64 / WAMP / XAMPP / PATH sıralamasıyla PHP binary bulur.
// WAMP'ta birden fazla PHP versiyonu olabilir — en yüksek versiyonu seçer.
func findPHP() string {
	wampBases := []string{
		`C:\wamp64`, `C:\wamp`,
		`D:\wamp64`, `D:\wamp`,
		`E:\wamp64`, `E:\wamp`,
	}
	for _, base := range wampBases {
		matches, _ := filepath.Glob(filepath.Join(base, "bin", "php", "php*", "php.exe"))
		if len(matches) > 0 {
			sort.Strings(matches) // sürüm sıralı: php8.x en sona gelir
			return matches[len(matches)-1]
		}
	}

	// XAMPP
	for _, drive := range []string{"C", "D", "E"} {
		p := drive + `:\xampp\php\php.exe`
		if _, err := os.Stat(p); err == nil {
			return p
		}
	}

	// PATH'te php var mı?
	if p, err := exec.LookPath("php"); err == nil {
		return p
	}
	return "php"
}

// findMySQLManager: WampManager veya XAMPP Control Panel yolunu döner.
// Bulunamazsa "" döner — ana program MySQL'in zaten açık olmasını bekler.
func findMySQLManager() string {
	candidates := []string{
		`C:\wamp64\wampmanager.exe`,
		`C:\wamp\wampmanager.exe`,
		`D:\wamp64\wampmanager.exe`,
		`D:\wamp\wampmanager.exe`,
		`E:\wamp64\wampmanager.exe`,
		`E:\wamp\wampmanager.exe`,
		`C:\xampp\xampp-control.exe`,
		`D:\xampp\xampp-control.exe`,
	}
	for _, p := range candidates {
		if _, err := os.Stat(p); err == nil {
			return p
		}
	}
	return ""
}

// findFlutter: yaygın kurulum konumlarını + PATH'i tarar.
func findFlutter() string {
	home, _ := os.UserHomeDir()
	candidates := []string{
		`C:\flutter\bin\flutter.bat`,
		`D:\flutter\bin\flutter.bat`,
		filepath.Join(home, "flutter", "bin", "flutter.bat"),
		filepath.Join(os.Getenv("LOCALAPPDATA"), "flutter", "bin", "flutter.bat"),
		filepath.Join(os.Getenv("PROGRAMFILES"), "flutter", "bin", "flutter.bat"),
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

// findADB: ANDROID_HOME / ANDROID_SDK_ROOT env değişkenlerini,
// Android Studio'nun varsayılan SDK konumunu ve PATH'i dener.
func findADB() string {
	for _, env := range []string{"ANDROID_HOME", "ANDROID_SDK_ROOT"} {
		if sdk := os.Getenv(env); sdk != "" {
			p := filepath.Join(sdk, "platform-tools", "adb.exe")
			if _, err := os.Stat(p); err == nil {
				return p
			}
		}
	}

	home, _ := os.UserHomeDir()
	candidates := []string{
		filepath.Join(os.Getenv("LOCALAPPDATA"), "Android", "Sdk", "platform-tools", "adb.exe"),
		filepath.Join(home, "AppData", "Local", "Android", "Sdk", "platform-tools", "adb.exe"),
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
