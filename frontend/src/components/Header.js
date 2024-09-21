import styled, { keyframes }  from "styled-components";
import { useNavigate } from "react-router-dom";
import { useState } from "react";
import { connectMetamask } from "../utils/connectMetamask";
import { ethers } from "ethers";
import { HubChainFactories, explorers } from "../constants/addresses";

export default function Header({
    address,
    setAddress,
    signer,
    setSigner,
    provider,
    setProvider
}) {
    const history = useNavigate();

    const [loading, setLoading] = useState(false);

    const handleConnectWallet = () => {
        connectMetamask().then((result) => {
            if (result) {
                setAddress(result.address);
                setSigner(result.web3Signer);
                setProvider(result.web3Provider);
            } else {
                alert("Failed to connect wallet");
            }
        });
    };
    

    const beautyAddress = (address) => {
        console.log(address);
        return `${address.slice(0, 6)}...${address.slice(-4)}`;
    }

    const handleCreateVault = async () => {
        try{
            const chainId = await signer.getChainId();
            console.log("chainId", chainId);

            const abi = [
                "function createVault() public returns (uint256)"
            ]
            const factoryContract = new ethers.Contract(
                HubChainFactories[Number(chainId)],
                abi,
                signer
            );

            factoryContract.createVault().then((tx) => {
                window.open(`${explorers[Number(chainId)]}tx/${tx.hash}`);
                console.log(tx);
            }).catch((err) => {
                console.log(err);
            });

            
        } catch (err) {
            console.log(err);
        }
    };

    return (
        <HeaderStyle>
            <h1>Logo</h1>
            <ButtonGroup>
            <HeaderButton onClick={handleCreateVault} disabled={loading}>
                    {loading ? <LoadingSpinner /> : "Create New Vault"}
                </HeaderButton>
                <HeaderButton onClick={handleConnectWallet}>{ address == "" ? "Connect Wallet" : beautyAddress(address)   }</HeaderButton>
            </ButtonGroup>
        </HeaderStyle>
    );
}

// Loading spinner animation
const spin = keyframes`
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
`;

const LoadingSpinner = styled.div`
    border: 4px solid #f3f3f3;
    border-top: 4px solid #007bff;
    border-radius: 50%;
    width: 16px;
    height: 16px;
    animation: ${spin} 1s linear infinite;
`;


const HeaderStyle = styled.header`
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 10px 20px;
    background-color: #f8f9fa;
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
    border-radius: 10px;
    margin-bottom: 20px;
    
    h1 {
        margin: 0;
        font-size: 24px;
    }
`;

const ButtonGroup = styled.div`
    display: flex;
    gap: 10px;
`;

const HeaderButton = styled.button`
    padding: 10px 20px;
    background-color: #007bff;
    color: white;
    border: none;
    border-radius: 5px;
    font-size: 16px;
    cursor: pointer;
    transition: background-color 0.2s, transform 0.2s;

    &:hover {
        background-color: #0056b3;
        transform: translateY(-2px);
    }

    &:active {
        transform: translateY(0);
    }
`;

