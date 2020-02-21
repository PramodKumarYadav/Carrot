package rabbit

import (
	"log"
	"strconv"
	"github.com/streadway/amqp"
)

func Publish(number int, channel *amqp.Channel, exchangeName string) {
	body := strconv.Itoa(number)
	err := channel.Publish(
		exchangeName, // exchange
		"",           // routing key
		false,        // mandatory
		false,        // immediate
		amqp.Publishing{
			ContentType: "text/plain",
			Body:        []byte(body),
		})
	log.Printf(" [x] Published %s", body)
	failOnError(err, "Failed to publish a message")
}

type process func([]byte) int

func Receive(channel *amqp.Channel, queueName string, processFunc process) {
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
			processFunc(d.Body)
		}
	}()

	log.Printf(" [*] Waiting for messages. To exit press CTRL+C")
	<-forever
}