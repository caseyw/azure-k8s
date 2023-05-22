package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

type Payload struct {
	Message   string `json:"message"`
	Timestamp int64  `json:"timestamp"`
}

func demo(w http.ResponseWriter, req *http.Request) {
	payload := &Payload{
		Message:   "Automate all the things!",
		Timestamp: time.Now().Unix(),
	}

	data, _ := json.Marshal(payload)
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	io.WriteString(w, string(data))
}

func main() {
	fmt.Println("Access the site via: http://localhost:8090")
	http.HandleFunc("/", demo)
	http.ListenAndServe(":8090", nil)
}
