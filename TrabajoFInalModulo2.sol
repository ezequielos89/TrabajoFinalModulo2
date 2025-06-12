    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.0;

    contract Subasta {
        address public owner;
        address public highestBidder;
        uint public highestBid;
        uint public auctionEndTime;
        uint public minIncrement = 5; // 5% incremento mínimo
        uint public commission = 2; // 2% comisión
        uint public extensionTime = 10 minutes;
        uint public minExtensionThreshold = 10 minutes;
        
        bool public ended;
        
        struct Bid {
            address bidder;
            uint amount;
            bool refunded;
        }
        
        Bid[] public bids;
        mapping(address => uint) public pendingReturns;
        
        event NewBid(address indexed bidder, uint amount);
        event AuctionEnded(address indexed winner, uint amount);
        event Refund(address indexed bidder, uint amount);
        
        modifier onlyOwner() {
            require(msg.sender == owner, "Solo el dueno puede ejecutar esto");
            _;
        }
        
        modifier auctionActive() {
            require(block.timestamp < auctionEndTime, "Subasta ya finalizo");
            require(!ended, "Subasta ya finalizo");
            _;
        }
        
        modifier auctionEnded() {
            require(block.timestamp >= auctionEndTime, "Subasta no ha finalizado");
            require(!ended, "Subasta ya finalizo");
            _;
        }
        
        constructor(uint _biddingTime) {
            owner = msg.sender;
            auctionEndTime = block.timestamp + _biddingTime;
        }
        
        function bid() external payable auctionActive {
            require(msg.value > 0, "Oferta debe ser mayor que 0");
            
            uint requiredMinBid = highestBid + (highestBid * minIncrement / 100);
            if (highestBid != 0) {
                require(msg.value >= requiredMinBid, "Oferta debe ser al menos 5% mayor que la oferta actual");
            }
            
            // Registrar oferta anterior para reembolso
            if (highestBidder != address(0)) {
                pendingReturns[highestBidder] += highestBid;
            }
            
            highestBidder = msg.sender;
            highestBid = msg.value;
            bids.push(Bid(msg.sender, msg.value, false));
            
            // Extender subasta si se ofrece en los últimos 10 minutos
            if (auctionEndTime - block.timestamp < minExtensionThreshold) {
                auctionEndTime += extensionTime;
            }
            
            emit NewBid(msg.sender, msg.value);
        }
        
        function withdraw() external returns (bool) {
            uint amount = pendingReturns[msg.sender];
            if (amount > 0) {
                pendingReturns[msg.sender] = 0;
                
                (bool success, ) = msg.sender.call{value: amount}("");
                if (!success) {
                    pendingReturns[msg.sender] = amount;
                    return false;
                }
                
                emit Refund(msg.sender, amount);
            }
            return true;
        }
        
        function partialRefund() external auctionActive returns (bool) {
            uint totalBidAmount = 0;
            uint lastValidBidIndex = 0;
            
            // Encontrar la última oferta válida del usuario
            for (uint i = bids.length - 1; i >= 0; i--) {
                if (bids[i].bidder == msg.sender && !bids[i].refunded) {
                    totalBidAmount += bids[i].amount;
                    lastValidBidIndex = i;
                    break;
                }
            }
            
            require(totalBidAmount > 0, "No hay ofertas para reembolsar");
            
            // Calcular el exceso (todo excepto la última oferta válida)
            uint excessAmount = totalBidAmount - bids[lastValidBidIndex].amount;
            
            if (excessAmount > 0) {
                pendingReturns[msg.sender] += excessAmount;
                
                // Marcar ofertas como reembolsadas (excepto la última)
                for (uint i = 0; i < lastValidBidIndex; i++) {
                    if (bids[i].bidder == msg.sender) {
                        bids[i].refunded = true;
                    }
                }
                
                return true;
            }
            
            return false;
        }
        
        function endAuction() external auctionEnded onlyOwner {
            require(!ended, "Subasta ya finalizo");
            
            ended = true;
            
            // Transferir monto ganador al dueño con comisión del 2%
            uint commissionAmount = (highestBid * commission) / 100;
            uint ownerAmount = highestBid - commissionAmount;
            
            (bool success, ) = owner.call{value: ownerAmount}("");
            require(success, "Transferencia fallida");
            
            emit AuctionEnded(highestBidder, highestBid);
        }
        
        function getBids() external view returns (Bid[] memory) {
            return bids;
        }
        
        function getWinner() external view returns (address, uint) {
            require(ended, "Subasta no ha finalizado");
            return (highestBidder, highestBid);
        }
        
        function getAuctionTimeLeft() external view returns (uint) {
            if (block.timestamp >= auctionEndTime) {
                return 0;
            }
            return auctionEndTime - block.timestamp;
        }
    }