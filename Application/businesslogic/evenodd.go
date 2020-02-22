package businesslogic

import (
	"encoding/json"
	"log"
	"strconv"

	"github.com/PramodKumarYadav/Carrot/evenoddapp/rabbit"
	"github.com/streadway/amqp"
)

const OddsExchangeName = "¹³⁵⁷⁹"
const EvensExchangeName = "⁰²⁴⁶⁸"
const ExchangeName = "🐧exchange"
const QueueName = "🐧queue"

var exchangeMap = map[bool]string{
	true:  EvensExchangeName,
	false: OddsExchangeName,
}

type NumberParity struct {
	Number int
	IsEven bool
}

func (data *NumberParity) ToJson() []byte {
	bytes, err := json.Marshal(data)
	failOnError(err, "eror in json marshalling")
	return bytes
}

func (data *NumberParity) GetExchange() string {
	return exchangeMap[data.IsEven]
}

func Process(body []byte, channel *amqp.Channel) {
	number, err := strconv.Atoi(string(body))
	failOnError(err, "failed to convert str to int: "+string(body))

	isEven := number%2 == 0
	getEvenStr := func() string { if isEven { return "even" } else { return "odd" }	}

	log.Printf("[🖥] received %d - it's %s", number, getEvenStr())

	result := &NumberParity{number, isEven}
	rabbit.Publish(result.ToJson(), channel, result.GetExchange())
}

func failOnError(err error, msg string) {
	if err != nil {
		log.Fatalf("%s: %s", msg, err)
	}
}
