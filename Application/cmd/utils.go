package cmd

import (
	"log"

	"github.com/streadway/amqp"
)

func failOnError(err error, msg string) {
	if err != nil {
		log.Fatalf("%s: %s", msg, err)
	}
}

func GetRabbitConnection()(*amqp.Connection) {
	conn, err := amqp.Dial("amqp://guest:guest@localhost:5672/")
	failOnError(err, "Failed to connect to RabbitMQ")
	return conn
}

func GetChannel(conn *amqp.Connection)(*amqp.Channel){
	ch, err := conn.Channel()
	failOnError(err, "Failed to open a channel")
	return ch
}

func CreateQueue(name string, channel *amqp.Channel)(amqp.Queue){
	queue, err := channel.QueueDeclare(
		name, // name
		false,   // durable
		false,   // delete when unused
		false,   // exclusive
		false,   // no-wait
		nil,     // arguments
	)
	failOnError(err, "Failed to declare " + name + " queue")
	return queue
}