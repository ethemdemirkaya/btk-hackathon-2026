package main

import (
	"bufio"
	"fmt"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"time"
)

// ANSI renk kodları (Windows 10+ destekler)
const (
	reset  = "\033[0m"
	bold   = "\033[1m"
	cyan   = "\033[96m"
	green  = "\033[92m"
	yellow = "\033[93m"
	red    = "\033[91m"
	gray   = "\033[90m"
	white  = "\033[97m"
	blue   = "\033[94m"
)

// Proje kökü (launcher/ klasörünün bir üstü)
func projectRoot() string {
	exe, _ := os.Executable()
	dir := filepath.Dir(exe)
	// development: go run main.go => launcher/ dizininden
	if filepath.Base(dir) == "launcher" {
		return filepath.Dir(dir)
	}
	// compiled exe proje kökünde ise direkt kullan
	return dir
}

func webDir(root string) string  { return filepath.Join(root, "web") }
func phpBin() string             { return `C:\wamp64\bin\php\php8.3.14\php.exe` }
func wampExe() string            { return `C:\wamp64\wampmanager.exe` }
func flutterBin() string         { return `C:\flutter\bin\flutter.bat` }
func adbBin() string {
	return filepath.Join(os.Getenv("LOCALAPPDATA"), "Android", "Sdk", "platform-tools", "adb.exe")
}

func log(color, symbol, msg string) {
	fmt.Printf("%s%s %s%s\n", color, symbol, msg, reset)
}

func logStep(msg string)    { log(cyan, "→", msg) }
func logOK(msg string)      { log(green, "✓", msg) }
func logWarn(msg string)    { log(yellow, "!", msg) }
func logError(msg string)   { log(red, "✗", msg) }
func logInfo(msg string)    { log(gray, "·", msg) }

func banner() {
	fmt.Println()
	fmt.Printf("%s%s╔══════════════════════════════════════════════════╗%s\n", bold, cyan, reset)
	fmt.Printf("%s%s║     PARANETTE — BTK AKADEMİ HACKATHON           ║%s\n", bold, white, reset)
	fmt.Printf("%s%s╚══════════════════════════════════════════════════╝%s\n", bold, cyan, reset)
	fmt.Println()
}

// MySQL portu açık mı?
func mysqlReady() bool {
	conn, err := net.DialTimeout("tcp", "127.0.0.1:3306", 1*time.Second)
	if err != nil {
		return false
	}
	conn.Close()
	return true
}

// Laravel sunucu portu açık mı?
func laravelReady() bool {
	conn, err := net.DialTimeout("tcp", "127.0.0.1:8000", 1*time.Second)
	if err != nil {
		return false
	}
	conn.Close()
	return true
}

// ADB cihaz listesine emülatör eklendi mi?
func emulatorReady() bool {
	out, err := exec.Command(adbBin(), "devices").Output()
	if err != nil {
		return false
	}
	return strings.Contains(string(out), "emulator-5554")
}

func waitUntil(check func() bool, label string, timeout time.Duration) bool {
	deadline := time.Now().Add(timeout)
	dots := 0
	for time.Now().Before(deadline) {
		if check() {
			fmt.Println()
			return true
		}
		dots++
		if dots%5 == 0 {
			fmt.Printf("\r%s  bekliyor: %s%s%s %-3d sn", gray, yellow, label, gray, int(time.Until(deadline).Seconds()))
		}
		time.Sleep(500 * time.Millisecond)
	}
	fmt.Println()
	return false
}

func startBackground(name string, args ...string) *exec.Cmd {
	cmd := exec.Command(name, args...)
	cmd.SysProcAttr = sysProcAttr() // platform-specific (aşağıda)
	if err := cmd.Start(); err != nil {
		logError(fmt.Sprintf("%s başlatılamadı: %v", name, err))
	}
	return cmd
}

func main() {
	// Windows'ta ANSI renk desteğini aktif et
	if runtime.GOOS == "windows" {
		enableVirtualTerminal()
	}

	banner()
	root := projectRoot()
	web := webDir(root)

	// ── 1. WampServer / MySQL ────────────────────────────────────────────────
	fmt.Printf("%s[1/5] MySQL kontrolü...%s\n", bold, reset)
	if mysqlReady() {
		logOK("MySQL zaten çalışıyor (port 3306)")
	} else {
		logStep("WampServer başlatılıyor...")
		startBackground(wampExe())
		if waitUntil(mysqlReady, "MySQL", 60*time.Second) {
			logOK("MySQL hazır")
		} else {
			logWarn("MySQL 60 saniyede hazır olmadı — devam ediliyor")
		}
	}
	fmt.Println()

	// ── 2. Laravel sunucusu ─────────────────────────────────────────────────
	fmt.Printf("%s[2/5] Laravel sunucusu...%s\n", bold, reset)
	if laravelReady() {
		logOK("Laravel zaten çalışıyor (port 8000)")
	} else {
		logStep("php artisan serve başlatılıyor...")
		laravelCmd := exec.Command(phpBin(), "artisan", "serve", "--host=127.0.0.1", "--port=8000")
		laravelCmd.Dir = web
		laravelCmd.SysProcAttr = sysProcAttr()
		if err := laravelCmd.Start(); err != nil {
			logError(fmt.Sprintf("Laravel başlatılamadı: %v", err))
		} else {
			if waitUntil(laravelReady, "Laravel", 30*time.Second) {
				logOK("Laravel hazır → http://127.0.0.1:8000")
			} else {
				logWarn("Laravel 30 saniyede yanıt vermedi")
			}
		}
	}
	fmt.Println()

	// ── 3. Android Emülatör ─────────────────────────────────────────────────
	fmt.Printf("%s[3/5] Android Emülatörü...%s\n", bold, reset)
	if emulatorReady() {
		logOK("Emülatör zaten çalışıyor (emulator-5554)")
	} else {
		logStep("Medium Phone emülatörü başlatılıyor...")
		startBackground(flutterBin(), "emulators", "--launch", "Medium_Phone")
		if waitUntil(emulatorReady, "Emülatör", 120*time.Second) {
			logOK("Emülatör hazır (emulator-5554)")
		} else {
			logWarn("Emülatör 120 saniyede hazır olmadı")
		}
	}
	fmt.Println()

	// ── 4. Emülatör boot tamamlanmasını bekle ───────────────────────────────
	fmt.Printf("%s[4/5] Emülatör boot kontrolü...%s\n", bold, reset)
	logStep("sys.boot_completed bekleniyor...")
	bootReady := false
	for i := 0; i < 60; i++ {
		out, _ := exec.Command(adbBin(), "-s", "emulator-5554", "shell",
			"getprop", "sys.boot_completed").Output()
		if strings.TrimSpace(string(out)) == "1" {
			bootReady = true
			break
		}
		time.Sleep(2 * time.Second)
	}
	if bootReady {
		logOK("Emülatör tamamen boot oldu")
	} else {
		logWarn("Boot kontrolü zaman aşımı — Flutter yükleniyor...")
	}
	fmt.Println()

	// ── 5. Flutter uygulaması ────────────────────────────────────────────────
	fmt.Printf("%s[5/5] Flutter uygulaması başlatılıyor...%s\n", bold, reset)
	logInfo(fmt.Sprintf("Proje: %s", filepath.Join(root, "mobile")))
	fmt.Println()

	// URL kartı
	fmt.Printf("%s%s┌─────────────────────────────────────────┐%s\n", bold, blue, reset)
	fmt.Printf("%s%s│  WEB   → http://127.0.0.1:8000          │%s\n", bold, white, reset)
	fmt.Printf("%s%s│  API   → http://127.0.0.1:8000/api/v1   │%s\n", bold, cyan, reset)
	fmt.Printf("%s%s│  MOBİL → http://10.0.2.2:8000/api/v1    │%s\n", bold, yellow, reset)
	fmt.Printf("%s%s└─────────────────────────────────────────┘%s\n", bold, blue, reset)
	fmt.Println()

	// Flutter'ı ön planda çalıştır (r=hot reload, R=restart, q=çıkış)
	mobileDir := filepath.Join(root, "mobile")
	flutterCmd := exec.Command(flutterBin(), "run", "-d", "emulator-5554")
	flutterCmd.Dir = mobileDir
	flutterCmd.Stdin = os.Stdin
	flutterCmd.Stdout = os.Stdout
	flutterCmd.Stderr = os.Stderr

	logOK("Flutter başlatıldı — r: hot reload | R: restart | q: çıkış")
	fmt.Println()

	if err := flutterCmd.Run(); err != nil {
		logError(fmt.Sprintf("Flutter çıktı: %v", err))
	}

	// Flutter kapandıktan sonra çıkmadan önce bekle
	fmt.Println()
	logInfo("Flutter oturumu bitti. Çıkmak için Enter'a bas...")
	bufio.NewReader(os.Stdin).ReadString('\n')
}
