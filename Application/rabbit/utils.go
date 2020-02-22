package rabbit

import (
	"log"

	"github.com/streadway/amqp"
)

func failOnError(err error, msg string) {
	if err != nil {
		log.Fatalf("%s: %s", msg, err)
	}
}

func GetRabbitConnection() *amqp.Connection {
	conn, err := amqp.Dial("amqp://guest:guest@localhost:5672/")
	failOnError(err, "Failed to connect to RabbitMQ")
	return conn
}

func GetChannel(conn *amqp.Connection) *amqp.Channel {
	ch, err := conn.Channel()
	failOnError(err, "Failed to open a channel")
	return ch
}

func CreateQueue(name string, channel *amqp.Channel) amqp.Queue {
	queue, err := channel.QueueDeclare(
		name,  // name
		false, // durable
		false, // delete when unused
		false, // exclusive
		false, // no-wait
		nil,   // arguments
	)
	failOnError(err, "Failed to declare "+name+" queue")
	return queue
}

func CreateExchange(name string, channel *amqp.Channel) *amqp.Channel {
	err := channel.ExchangeDeclare(
		name,     //name
		"fanout", // kind
		true,     // durable
		false,    //autodelete
		false,    // internal
		false,    // nowait
		nil)
	failOnError(err, "failed to declare exchange "+name)
	return channel
}

func BindExchangeToExchange(sourceExchange, destinationExchange string, channel *amqp.Channel) *amqp.Channel {
	//ExchangeBind(destination, key, source string, noWait bool, args Table)
	err := channel.ExchangeBind(
		destinationExchange,
		"",
		sourceExchange,
		false,
		nil)
	failOnError(err, " Could not create exchnage binding"+sourceExchange+" => "+destinationExchange)
	return channel
}

func BindQueueToExchange(queue amqp.Queue, exchangeName string, channel *amqp.Channel) *amqp.Channel {
	err := channel.QueueBind(
		queue.Name,
		"",
		exchangeName,
		false,
		nil)
	failOnError(err, "Could not bind queue "+queue.Name+" to exchange "+exchangeName)
	return channel
}
