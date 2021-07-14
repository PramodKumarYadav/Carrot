package rabbit

import (
	"log"
	"github.com/streadway/amqp"
)

func Publish(body []byte, channel *amqp.Channel, exchangeName string) {
	err := channel.Publish(
		exchangeName, // exchange
		"",           // routing key
		false,        // mandatory
		false,        // immediate
		amqp.Publishing{
			ContentType: "text/plain",
			Body:        body,
		})
	log.Printf(" [🥕] Published %s to %s", body, exchangeName)
	failOnError(err, "Failed to publish a message")
}

type processBody func([]byte, *amqp.Channel) 

func Receive(channel *amqp.Channel, queueName string, processFunc processBody) {
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
			processFunc(d.Body, channel)
		}
	}()

	log.Printf(" [*] Waiting for messages. To exit press CTRL+C")
	<-forever
}