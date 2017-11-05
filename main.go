//go:generate goyacc -o cal.go -p "cal" cal.y
package main

import (
	"bufio"
	"io"
	"log"
	"os"
)

func main() {
	in := bufio.NewReader(os.Stdin)
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
