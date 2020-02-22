package main

import (
	"fmt"
	"strconv"
	"time"
	"github.com/streadway/amqp"
	"github.com/PramodKumarYadav/Carrot/evenoddapp/businesslogic"
	"github.com/PramodKumarYadav/Carrot/evenoddapp/rabbit"
)

func main() {

	connection := rabbit.GetRabbitConnection()
	defer connection.Close()

	channel := rabbit.GetChannel(connection)
	defer channel.Close()

	createTopology(channel)

	// start receiving
	go rabbit.Receive(channel, businesslogic.QueueName, businesslogic.Process)

	// publish
	sendFirstNNumbers(9001, channel, businesslogic.ExchangeName)

	// TODO die properly not after 10 seconds
	time.Sleep(10 * time.Second)
	fmt.Println("main function completed")
}

func sendFirstNNumbers(n int, channel *amqp.Channel, exchangeName string) {
	for i := 0; i < n; i++ {
		body := []byte(strconv.Itoa(i))
		go rabbit.Publish(body, channel, exchangeName)
	}
}

func createTopology(channel *amqp.Channel) {
	// topology is inspired by what MassTransit does

	// tried nesting functions but it ends up unreadable - TODO refactor
	rabbit.BindQueueToExchange( // bind '🐧queue' queue to '🐧queue' exchange
		rabbit.CreateQueue(businesslogic.QueueName, channel), // create '🐧queue' queue
		businesslogic.ExchangeName,
		rabbit.BindExchangeToExchange( // bind '🐧queue' exchange to '🐧exchange' exchange
			businesslogic.ExchangeName,
			businesslogic.QueueName,
			rabbit.CreateExchange( // create '🐧queue' exchange
				businesslogic.QueueName, // same name as queue
				rabbit.CreateExchange(businesslogic.ExchangeName, channel)))) // create '🐧exchange' exchange

	rabbit.CreateExchange(businesslogic.EvensExchangeName, channel)
	rabbit.CreateExchange(businesslogic.OddsExchangeName, channel)
}
