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

// ANSI renk kodları (Windows 10+ ve Unix terminalleri destekler)
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

// Proje kökü: launcher/ dizininin bir üstü
func projectRoot() string {
	exe, _ := os.Executable()
	dir := filepath.Dir(exe)
	if filepath.Base(dir) == "launcher" {
		return filepath.Dir(dir)
	}
	return dir
}

func webDir(root string) string { return filepath.Join(root, "web") }

func logLine(color, symbol, msg string) {
	fmt.Printf("%s%s %s%s\n", color, symbol, msg, reset)
}

func logStep(msg string)  { logLine(cyan, "→", msg) }
func logOK(msg string)    { logLine(green, "✓", msg) }
func logWarn(msg string)  { logLine(yellow, "!", msg) }
func logError(msg string) { logLine(red, "✗", msg) }
func logInfo(msg string)  { logLine(gray, "·", msg) }

func banner() {
	fmt.Println()
	fmt.Printf("%s%s╔══════════════════════════════════════════════════╗%s\n", bold, cyan, reset)
	fmt.Printf("%s%s║     PARANETTE — BTK AKADEMİ HACKATHON           ║%s\n", bold, white, reset)
	fmt.Printf("%s%s╚══════════════════════════════════════════════════╝%s\n", bold, cyan, reset)
	fmt.Println()
}

// ── Bağlantı kontrolleri ──────────────────────────────────────────────────

func portOpen(host string, port int) bool {
	conn, err := net.DialTimeout("tcp", fmt.Sprintf("%s:%d", host, port), time.Second)
	if err != nil {
		return false
	}
	conn.Close()
	return true
}

func mysqlReady() bool    { return portOpen("127.0.0.1", 3306) }
func laravelReady() bool  { return portOpen("127.0.0.1", 8000) }

func emulatorReady(adb string) bool {
	out, err := exec.Command(adb, "devices").Output()
	if err != nil {
		return false
	}
	return strings.Contains(string(out), "emulator-")
}

// ── Bekleme yardımcısı ────────────────────────────────────────────────────

func waitUntil(check func() bool, label string, timeout time.Duration) bool {
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		if check() {
			fmt.Println()
			return true
		}
		fmt.Printf("\r%s  bekliyor: %s%s%s %-3d sn",
			gray, yellow, label, gray, int(time.Until(deadline).Seconds()))
		time.Sleep(500 * time.Millisecond)
	}
	fmt.Println()
	return false
}

// ── Arka plan process ─────────────────────────────────────────────────────

func startBackground(name string, args ...string) *exec.Cmd {
	cmd := exec.Command(name, args...)
	cmd.SysProcAttr = sysProcAttr()
	if err := cmd.Start(); err != nil {
		logError(fmt.Sprintf("%s başlatılamadı: %v", name, err))
	}
	return cmd
}

// ── AVD otomatik algılama ─────────────────────────────────────────────────

func detectAVD(flutter string) string {
	preferred := []string{"Medium_Phone", "Pixel_8", "Pixel_6", "Pixel_4"}

	out, err := exec.Command(flutter, "emulators").CombinedOutput()
	if err != nil {
		return preferred[0]
	}

	lines := strings.Split(string(out), "\n")
	var first string

	for _, line := range lines {
		// Format: "• AVD_NAME  • Label • vendor • platform"
		if !strings.HasPrefix(strings.TrimSpace(line), "•") {
			continue
		}
		parts := strings.Split(line, "•")
		if len(parts) < 2 {
			continue
		}
		id := strings.TrimSpace(parts[1])
		if id == "" {
			continue
		}
		if first == "" {
			first = id
		}
		for _, p := range preferred {
			if strings.EqualFold(id, p) {
				return id
			}
		}
	}
	if first != "" {
		return first
	}
	return preferred[0]
}

// ── Main ──────────────────────────────────────────────────────────────────

func main() {
	if runtime.GOOS == "windows" {
		enableVirtualTerminal()
	}

	banner()

	// Platform'a göre binary yollarını otomatik bul
	php     := findPHP()
	mysql   := findMySQLManager()
	flutter := findFlutter()
	adb     := findADB()

	logInfo(fmt.Sprintf("PHP     : %s", php))
	logInfo(fmt.Sprintf("Flutter : %s", flutter))
	logInfo(fmt.Sprintf("ADB     : %s", adb))
	if mysql != "" {
		logInfo(fmt.Sprintf("MySQL   : %s", mysql))
	}
	fmt.Println()

	root := projectRoot()
	web  := webDir(root)

	// ── 1. MySQL ─────────────────────────────────────────────────────────
	fmt.Printf("%s[1/5] MySQL kontrolü...%s\n", bold, reset)
	if mysqlReady() {
		logOK("MySQL zaten çalışıyor (port 3306)")
	} else if mysql != "" {
		logStep(fmt.Sprintf("Başlatılıyor: %s", filepath.Base(mysql)))
		startBackground(mysql)
		if waitUntil(mysqlReady, "MySQL", 60*time.Second) {
			logOK("MySQL hazır")
		} else {
			logWarn("MySQL 60 saniyede hazır olmadı — devam ediliyor")
		}
	} else {
		logWarn("MySQL yöneticisi bulunamadı. MySQL'in çalıştığından emin olun.")
	}
	fmt.Println()

	// ── 2. Laravel ───────────────────────────────────────────────────────
	fmt.Printf("%s[2/5] Laravel sunucusu...%s\n", bold, reset)
	if laravelReady() {
		logOK("Laravel zaten çalışıyor (port 8000)")
	} else {
		logStep("php artisan serve başlatılıyor...")
		laravelCmd := exec.Command(php, "artisan", "serve", "--host=127.0.0.1", "--port=8000")
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

	// ── 3. Android Emülatör ──────────────────────────────────────────────
	fmt.Printf("%s[3/5] Android Emülatörü...%s\n", bold, reset)
	avd := detectAVD(flutter)
	if emulatorReady(adb) {
		logOK("Emülatör zaten çalışıyor")
	} else {
		logStep(fmt.Sprintf("AVD başlatılıyor: %s", avd))
		startBackground(flutter, "emulators", "--launch", avd)
		if waitUntil(func() bool { return emulatorReady(adb) }, "Emülatör", 120*time.Second) {
			logOK("Emülatör hazır")
		} else {
			logWarn("Emülatör 120 saniyede hazır olmadı")
		}
	}
	fmt.Println()

	// ── 4. Boot tamamlanmasını bekle ─────────────────────────────────────
	fmt.Printf("%s[4/5] Emülatör boot kontrolü...%s\n", bold, reset)
	logStep("sys.boot_completed bekleniyor...")
	bootReady := false
	for i := 0; i < 60; i++ {
		out, _ := exec.Command(adb, "wait-for-device", "shell",
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

	// ── 5. Flutter ───────────────────────────────────────────────────────
	fmt.Printf("%s[5/5] Flutter uygulaması başlatılıyor...%s\n", bold, reset)
	logInfo(fmt.Sprintf("Proje: %s", filepath.Join(root, "mobile")))
	fmt.Println()

	fmt.Printf("%s%s┌─────────────────────────────────────────┐%s\n", bold, blue, reset)
	fmt.Printf("%s%s│  WEB   → http://127.0.0.1:8000          │%s\n", bold, white, reset)
	fmt.Printf("%s%s│  API   → http://127.0.0.1:8000/api/v1   │%s\n", bold, cyan, reset)
	fmt.Printf("%s%s│  MOBİL → http://10.0.2.2:8000/api/v1    │%s\n", bold, yellow, reset)
	fmt.Printf("%s%s└─────────────────────────────────────────┘%s\n", bold, blue, reset)
	fmt.Println()

	mobileDir := filepath.Join(root, "mobile")
	flutterCmd := exec.Command(flutter, "run", "-d", "emulator-5554")
	flutterCmd.Dir = mobileDir
	flutterCmd.Stdin = os.Stdin
	flutterCmd.Stdout = os.Stdout
	flutterCmd.Stderr = os.Stderr

	logOK("Flutter başlatıldı — r: hot reload | R: restart | q: çıkış")
	fmt.Println()

	if err := flutterCmd.Run(); err != nil {
		logError(fmt.Sprintf("Flutter çıktı: %v", err))
	}

	fmt.Println()
	logInfo("Flutter oturumu bitti. Çıkmak için Enter'a bas...")
	bufio.NewReader(os.Stdin).ReadString('\n')
}
