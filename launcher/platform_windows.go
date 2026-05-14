package main

import (
	"os/exec"
	"syscall"

	"golang.org/x/sys/windows"
)

// Windows'ta arka plan işlemi için: yeni process group, pencere gösterme
func sysProcAttr() *syscall.SysProcAttr {
	return &syscall.SysProcAttr{
		CreationFlags: syscall.CREATE_NEW_PROCESS_GROUP,
		HideWindow:    false,
	}
}

// Windows sanal terminal (ANSI renk) desteğini aktif et
func enableVirtualTerminal() {
	stdout := windows.Handle(uintptr(syscall.Stdout))
	var mode uint32
	windows.GetConsoleMode(stdout, &mode)
	windows.SetConsoleMode(stdout, mode|windows.ENABLE_VIRTUAL_TERMINAL_PROCESSING)
}

// windows.CreateProcess gibi düşük seviyeli yöntemler kullanmak yerine
// exec.Cmd ile basit başlatma
var _ = exec.Command
