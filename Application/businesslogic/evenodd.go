package businesslogic

import (
	"log"
	"strconv"
)

func Process(x []byte) int {
	number, err := strconv.Atoi(string(x))
	failOnError(err, "failed to convert str to int: "+string(x))
	log.Printf("%d", number)

	isEven := number%2 == 0
	getEvenStr := func() string {
		if isEven {
			return "even"
		} else {
			return "odd"
		}
	}

	log.Printf("%d - it's %s", number, getEvenStr())
	return number
}

func Even(number int) {

}

func failOnError(err error, msg string) {
	if err != nil {
		log.Fatalf("%s: %s", msg, err)
	}
}
