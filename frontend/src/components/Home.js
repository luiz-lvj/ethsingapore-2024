import styled from "styled-components";
import { useNavigate } from "react-router-dom";
import { useEffect, useState } from "react";
import Header from "./Header";
import { ethers } from "ethers";
import { HubChainFactories } from "../constants/addresses";

export default function Home(
    {
        address,
        setAddress,
        signer,
        setSigner,
        provider,
        setProvider
    }
) {
    const history = useNavigate();

    const [cards, setCards] = useState([]);


    // Example list of cards data
    // const cards = [
    //     { id: 1, title: "Card 1", description: "This is card 1" },
    //     { id: 2, title: "Card 2", description: "This is card 2" },
    //     { id: 3, title: "Card 3", description: "This is card 3" },
    //     { id: 4, title: "Card 4", description: "This is card 4" },
    //     { id: 5, title: "Card 5", description: "This is card 5" },
    // ];

    const chains = [
        { id: 1, name: "Ethereum", imageUrl: "https://cryptorunner.com/wp-content/uploads/2019/03/ethereum-cryptocurrency-logo.png" },
        { id: 2, name: "Linea", imageUrl: "https://img.cryptorank.io/coins/linea1680021297845.png" }
    ];

    const getVaults = async () => {
        try{
            const chainId = await signer.getChainId();
            console.log("chainId", chainId);

            const abi = [
                "function vaultCounter() public view returns (uint256)"
            ]
            const factoryContract = new ethers.Contract(
                HubChainFactories[Number(chainId)],
                abi,
                signer
            );

            const totalBigNumber = await factoryContract.vaultCounter();

            const total = parseInt(totalBigNumber._hex, 16);

            let tmpCards = []

            for(let i = 0; i < total; i++){
                tmpCards.push({id: i, title: `Vault ${i}`, description: `This is vault ${i}`});
                
            }

            setCards([...tmpCards]);


            
        } catch (err) {
            console.log(err);
        }
    };

    useEffect(() => {

        if(address == ""){
            return;
        }

        getVaults();







    },[address]);

    // Handle card click
    const handleCardClick = (id) => {
        history(`/vault/${id}`);
    };

    return (
        <HomeStyle>

            <Header   
            address={address}
            setAddress={setAddress}
            signer={signer}
            setSigner={setSigner}
            provider={provider}
            setProvider={setProvider}
            
            />

            <AvailableChains>
                <h2>Available Chains</h2>
                <ChainsContainer>
                    {chains.map((chain) => (
                        <ChainImage key={chain.id} src={chain.imageUrl} alt={chain.name} />
                    ))}
                </ChainsContainer>
            </AvailableChains>
            
            <CardGrid>
                {cards.map((card) => (
                    <Card key={card.id} onClick={() => handleCardClick(card.id)}>
                        <h3>{card.title}</h3>
                        <p>{card.description}</p>
                    </Card>
                ))}
            </CardGrid>
        </HomeStyle>
    );
}
// Styled components
const HomeStyle = styled.div`
    padding: 20px;
`;

const AvailableChains = styled.div`
    text-align: center;
    margin-bottom: 20px;
`;

const ChainsContainer = styled.div`
    display: flex;
    justify-content: center;
    gap: 20px;
    margin-top: 10px;
`;

const ChainImage = styled.img`
    width: 50px;
    height: 50px;
    object-fit: contain;
`;

const CardGrid = styled.div`
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: 20px;
`;

const Card = styled.div`
    background-color: #f0f0f0;
    padding: 20px;
    border-radius: 10px;
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
    transition: transform 0.2s, box-shadow 0.2s;
    cursor: pointer;

    &:hover {
        transform: translateY(-5px);
        box-shadow: 0 6px 12px rgba(0, 0, 0, 0.15);
    }

    h3 {
        margin-bottom: 10px;
        font-size: 18px;
    }

    p {
        font-size: 14px;
        color: #555;
    }
`;