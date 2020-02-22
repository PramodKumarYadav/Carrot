package businesslogic

import (
	"log"
	"strconv"
	"github.com/streadway/amqp"
	"github.com/PramodKumarYadav/Carrot/evenoddapp/rabbit"
	"encoding/json"
)

const OddsExchangeName = "¹³⁵⁷⁹"
const EvensExchangeName = "⁰²⁴⁶⁸"
const ExchangeName = "🐧exchange"
const QueueName = "🐧queue"

type NumberOddity struct {
    Number int
    IsEven bool
}

func (data *NumberOddity) ToJson() []byte {
	bytes, err := json.Marshal(data)
	failOnError(err, "eror in json marshalling")
	return bytes
}

func (data *NumberOddity) GetExchange() string{
	exchangeMap := map[bool]string{
		true: EvensExchangeName,
		false: OddsExchangeName,
	}
	return exchangeMap[data.IsEven]
}

func Process(body []byte, channel *amqp.Channel) {
	number, err := strconv.Atoi(string(body))
	failOnError(err, "failed to convert str to int: "+string(body))

	isEven := number%2 == 0
	getEvenStr := func() string { if isEven { return "even" } else { return "odd" }	}

	log.Printf("%d - it's %s", number, getEvenStr())

	result :=  &NumberOddity{ number, isEven }

	rabbit.Publish(result.ToJson(), channel, result.GetExchange())
}

func failOnError(err error, msg string) {
	if err != nil {
		log.Fatalf("%s: %s", msg, err)
	}
}
