package main

import (
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"unsafe"

	"golang.org/x/sys/windows"
)

// Constantes de Windows
const (
	MOD_ALT      = 0x0001
	MOD_CONTROL  = 0x0002
	MOD_SHIFT    = 0x0004
	MOD_WIN      = 0x0008
	MOD_NOREPEAT = 0x4000

	WM_HOTKEY = 0x0312

	VK_SPACE = 0x20
)

var (
	user32           = windows.NewLazySystemDLL("user32.dll")
	procRegisterHotKey = user32.NewProc("RegisterHotKey")
	procUnregisterHotKey = user32.NewProc("UnregisterHotKey")
	procGetMessage     = user32.NewProc("GetMessageW")
	procTranslateMessage = user32.NewProc("TranslateMessage")
	procDispatchMessage = user32.NewProc("DispatchMessageW")
)

// MSG estructura para mensajes de Windows
type MSG struct {
	Hwnd    uintptr
	Message uint32
	WParam  uintptr
	LParam  uintptr
	Time    uint32
	Pt      struct {
		X, Y int32
	}
}

// Estado de grabación
var (
	isRecording bool
	hotkeyID    int32 = 1
)

// onHotKey se llama cuando se presiona Ctrl+Space
func onHotKey() {
	isRecording = !isRecording
	if isRecording {
		fmt.Println("▶ Grabación INICIADA (Ctrl+Space)")
	} else {
		fmt.Println("⏹ Grabación DETENIDA (Ctrl+Space)")
	}
}

func main() {
	fmt.Println("=== Hotkey Global Ctrl+Space ===")
	fmt.Println("Presiona Ctrl+Space para iniciar/detener grabación")
	fmt.Println("Presiona Ctrl+C para salir")
	fmt.Println()

	// Registrar la hotkey: Ctrl + Space
	// fsModifiers = MOD_CONTROL (0x0002) | MOD_NOREPEAT (0x4000) = 0x4002
	// vk = VK_SPACE (0x20)
	mods := MOD_CONTROL | MOD_NOREPEAT
	ret, _, err := procRegisterHotKey.Call(
		0,                    // hWnd = NULL (no asociada a ventana)
		uintptr(hotkeyID),    // id
		uintptr(mods),        // fsModifiers
		uintptr(VK_SPACE),    // vk
	)
	if ret == 0 {
		log.Fatalf("Error registrando hotkey: %v", err)
	}
	fmt.Println("✓ Hotkey Ctrl+Space registrada exitosamente")
	defer func() {
		procUnregisterHotKey.Call(0, uintptr(hotkeyID))
		fmt.Println("✓ Hotkey desregistrada")
	}()

	// Canal para señal de salida
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// Loop de mensajes en goroutine
	msgChan := make(chan MSG, 10)
	go messageLoop(msgChan)

	// Procesar mensajes hasta que llegue señal de salida
	done := false
	for !done {
		select {
		case msg := <-msgChan:
			if msg.Message == WM_HOTKEY {
				onHotKey()
			}
		case <-sigChan:
			fmt.Println("\n✓ Señal de salida recibida")
			done = true
		}
	}
}

func messageLoop(msgChan chan<- MSG) {
	for {
		var msg MSG
		// GetMessageW espera hasta que haya un mensaje
		ret, _, _ := procGetMessage.Call(
			uintptr(unsafe.Pointer(&msg)),
			0, // hWnd = NULL
			0, // wMsgFilterMin
			0, // wMsgFilterMax
		)
		if ret == 0 {
			// WM_QUIT
			close(msgChan)
			return
		}

		// Enviar mensaje al canal principal
		msgChan <- msg

		// Traducir y despachar mensajes de teclado virtual
		procTranslateMessage.Call(uintptr(unsafe.Pointer(&msg)))
		procDispatchMessage.Call(uintptr(unsafe.Pointer(&msg)))
	}
}
