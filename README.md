# TrabajoFinalModulo2
Subasta - Smart Contract

## Descripción
Contrato inteligente para un sistema de subastas descentralizado implementado en Solidity.

## Características principales
- Sistema de pujas con incremento mínimo del 5%
- Comisión del 2% para el owner
- Mecanismo de extensión automática
- Reembolsos seguros

## Dirección en Sepolia
https://sepolia.etherscan.io/tx/0x07cbac11db09fb31fc039d1fb57f32487d0c140b047def95902b0f5091b347f4



Funciones Principales
bid()

Propósito: Realizar una oferta en la subasta

Lógica:

Exige que el valor enviado sea ≥5% mayor que la oferta actual

Registra la oferta anterior en pendingReturns para reembolso

Extiende la subasta 10 minutos si se ofrece en los últimos 10 minutos

Restricciones: Solo activa durante el periodo de subasta (auctionActive)

withdraw()

Propósito: Reclamar fondos de ofertas superadas

Lógica:

Transfiere el monto acumulado en pendingReturns

Previene reentrancia (reset a 0 antes de transferir)

Retorno: bool (éxito de la transferencia)

partialRefund()

Propósito: Recuperar fondos de ofertas anteriores (excepto la última)

Lógica:

Busca la última oferta válida del usuario

Calcula el exceso (suma de ofertas anteriores)

Marca ofertas como reembolsadas

Restricciones: Solo durante la subasta (auctionActive)

Funciones del Dueño
endAuction()

Propósito: Finalizar la subasta y cobrar

Lógica:

Transfiere el monto ganador (menos 2% de comisión) al owner

Marca la subasta como terminada (ended = true)

Restricciones:

Solo el dueño (onlyOwner)

Subasta debe haber finalizado (auctionEnded)

Funciones de Consulta (view)
getBids()

Retorna: Array con todas las ofertas (Bid[])

Datos: Dirección, monto y estado de reembolso de cada oferta

getWinner()

Retorna: Dirección y monto del ganador (address, uint)

Restricción: Solo si la subasta terminó (ended)

getAuctionTimeLeft()

Retorna: Segundos restantes para el cierre (uint)

Nota: Devuelve 0 si el tiempo ya expiró



Variables Públicas (auto-generan getters)
owner: Dirección del creador

highestBidder/highestBid: Oferta líder actual

auctionEndTime: Timestamp de finalización

ended: Estado booleano de la subasta

minIncrement/commission/extensionTime: Parámetros configurables



Eventos
NewBid: Al recibir una oferta válida

AuctionEnded: Al finalizar (ganador + monto)

Refund: Al procesar un reembolso

Estructura típica de uso:

Participantes → bid()

Dueño → endAuction()

Perdedores → withdraw() o partialRefund()

