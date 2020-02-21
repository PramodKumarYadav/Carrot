package main

import (
	"fmt"
	"qwertoyo/carrot/evenoddapp/rabbit"
	"qwertoyo/carrot/evenoddapp/businesslogic"
	"time"
	"github.com/streadway/amqp"
)

// to the reader: these are my first Go lines - be clement 🐣
const exchangeName = "🐧exchange"
const queueName = "🐧queue"

func main() {

	connection := rabbit.GetRabbitConnection()
	defer connection.Close()

	channel := rabbit.GetChannel(connection)
	defer channel.Close()

	createTopology(channel)

	// start receiving
	go rabbit.Receive(channel, queueName, businesslogic.Process)

	// publish
	sendFirstNNumbers(9001, channel, exchangeName)

	// TODO die properly not after 10 seconds
	time.Sleep(10 * time.Second)
	fmt.Println("main function completed")
}

func sendFirstNNumbers(n int, channel *amqp.Channel, exchangeName string) {
	for i := 0; i < n; i++ {
		go rabbit.Publish(i, channel, exchangeName)
	}
}

func createTopology(channel *amqp.Channel){
	// topology is inspired by what MassTransit does

	rabbit.BindQueueToExchange( // bind '🐧queue' queue to '🐧queue' exchange
		rabbit.CreateQueue(queueName, channel), // create '🐧queue' queue
	 	exchangeName, 
		rabbit.BindExchangeToExchange( // bind '🐧queue' exchange to '🐧exchange' exchange
			exchangeName, 
			queueName, 	
			rabbit.CreateExchange( // create '🐧queue' exchange
				queueName, // same name as queue
				rabbit.CreateExchange(exchangeName, channel)))) // create '🐧exchange' exchange
}
