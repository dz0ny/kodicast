package main

import (
	"errors"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/anacrolix/tagflag"
	"github.com/pdf/kodirpc"
)

var version = ""
var commitHash = ""
var branch = ""
var buildTime = ""

var flags = struct {
	Addr  *net.TCPAddr `help:"HTTP listen address"`
	File  string       `help:"File-based storage directory, overrides piece storage"`
	Debug bool         `help:"Verbose output"`
}{
	Debug: false,
}

func IsUp(v net.Flags) bool {
	return v&net.FlagUp == net.FlagUp
}

func IsCast(v net.Flags) bool {
	return v&(net.FlagBroadcast|net.FlagMulticast) != 0
}

func GetIP() (ip net.IP, err error) {
	ifaces, err := net.Interfaces()

	for _, i := range ifaces {
		log.Println(i.Name)
		if i.Name == "lo" {
			continue
		}
		if !IsCast(i.Flags) && !IsUp(i.Flags) {
			continue
		}
		addrs, err := i.Addrs()
		if err != nil {
			return nil, err
		}
		for _, addr := range addrs {
			switch v := addr.(type) {
			case *net.IPNet:
				ip = v.IP
			case *net.IPAddr:
				ip = v.IP
			}
			return ip, nil
		}
	}
	return nil, errors.New("IP was not found")
}

func GetPort() int {
	addr, err := net.ResolveTCPAddr("tcp", "localhost:0")
	if err != nil {
		panic(err)
	}

	l, err := net.ListenTCP("tcp", addr)
	if err != nil {
		panic(err)
	}
	defer l.Close()
	return l.Addr().(*net.TCPAddr).Port
}

func main() {
	log.SetFlags(log.Flags() | log.Lshortfile)
	tagflag.Description(fmt.Sprintf("KODICast %s built at %s from commit %s@%s", version, buildTime, commitHash, branch))
	tagflag.Parse(&flags)
	log.Println(flags)

	_, err := os.Stat(flags.File)
	if err != nil {
		log.Fatalln(err)
	}

	port := GetPort()
	ip, err := GetIP()
	if err != nil {
		log.Fatalln(err)
	}

	http.HandleFunc("/play", func(w http.ResponseWriter, r *http.Request) {
		http.ServeFile(w, r, flags.File)
	})

	go http.ListenAndServe(fmt.Sprintf(":%d", port), nil)

	config := kodirpc.NewConfig()
	client, err := kodirpc.NewClient(flags.Addr.String(), config)
	if err != nil {
		log.Fatalln(err)
	}
	cmd := map[string]interface{}{
		`item`: map[string]string{`file`: fmt.Sprintf("http://%s:%d/play", ip, port)},
	}
	log.Println(cmd)
	log.Println(client.Call("Player.Open", cmd))

	ch := make(chan os.Signal)
	signal.Notify(ch, syscall.SIGINT, syscall.SIGTERM)
	<-ch //block
}
