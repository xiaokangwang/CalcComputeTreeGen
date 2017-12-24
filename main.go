//go:generate goyacc -o cal.go -p "cal" cal.y
package main

import (
	"bufio"
	"io"
	"log"
	"os"
)

func main() {
	//f, _ := os.Open("calcdata")
	in := bufio.NewReader(os.Stdin)
	//in := bufio.NewReader(f)
	for {
		if _, err := os.Stdout.WriteString("> "); err != nil {
			log.Fatalf("WriteString: %s", err)
		}
		line, err := in.ReadBytes('\n')
		if err == io.EOF {
			return
		}
		if err != nil {
			log.Fatalf("ReadBytes: %s", err)
		}

		calParse(&calLex{line: line})
	}
}
