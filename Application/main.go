package main

import (
	"fmt"
	"qwertoyo/carrot/evenoddapp/cmd"
	"time"
	"github.com/streadway/amqp"
)

// to the reader: these are my first Go lines - be clement 🐣

func main() {

	connection := cmd.GetRabbitConnection()
	defer connection.Close()

	channel := cmd.GetChannel(connection)
	defer channel.Close()

	queue := cmd.CreateQueue("input", channel)

	go cmd.Receive(channel, "input")

	sendFirstNNumbers(99, channel, queue.Name)

	// TODO use a channel and die properly not after 10 seconds
	time.Sleep(10 * time.Second)
	fmt.Println("main function completed")
}


func sendFirstNNumbers(n int, channel *amqp.Channel, queueName string){
	for i := 0; i < n; i++ {
		go cmd.Send(i, channel, queueName)
	}
}
