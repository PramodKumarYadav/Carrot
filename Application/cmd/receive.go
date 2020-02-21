package cmd

import (
	"log"
	"strconv"
	"github.com/streadway/amqp"
)

func Receive(channel *amqp.Channel, queueName string) {
	msgs, err := channel.Consume(
		queueName, // queue
		"",        // consumer
		true,      // auto-ack
		false,     // exclusive
		false,     // no-local
		false,     // no-wait
		nil,       // args
	)
	failOnError(err, "Failed to register a consumer")

	forever := make(chan bool)

	counter := 0

	go func() {
		for d := range msgs {
			counter++
			process(d.Body)
			//log.Printf("%d Received a message: %s", counter, d.Body)
		}
	}()

	log.Printf(" [*] Waiting for messages. To exit press CTRL+C")
	<-forever
}

func process(x []byte) {
	number, err := strconv.Atoi(string(x))
	failOnError(err, "failed to convert str to int: " + string(x))
	log.Printf("%d", number);

	isEven := number%2 == 0
	getEvenStr := func() string { if isEven { return "even" } else { return "odd" } }()

	log.Printf("%d - it's %s", number, getEvenStr);

}
