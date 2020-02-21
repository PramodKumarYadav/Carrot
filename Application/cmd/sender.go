package cmd

import (
	"log"
	"strconv"
	"github.com/streadway/amqp"
)


func Send(number int, channel *amqp.Channel, queueName string) {
	body := strconv.Itoa(number)
	err := channel.Publish(
		"",     // exchange
		queueName, // routing key
		false,  // mandatory
		false,  // immediate
		amqp.Publishing{
			ContentType: "text/plain",
			Body:        []byte(body),
		})
	log.Printf(" [x] Sent %s", body)
	failOnError(err, "Failed to publish a message")
}