import styled from "styled-components";
import { useNavigate, useParams } from "react-router-dom";
import { useEffect, useState } from "react";
import Header from "./Header";
import { ethers } from "ethers";
import { HubChainFactories, currencies, explorers } from "../constants/addresses";

export default function VaultPage({
    address,
    setAddress,
    signer,
    setSigner,
    provider,
    setProvider,
}) {
    const { id } = useParams();

    const [vault, setVault] = useState(null);
    const [totalValueLocked, setTotalValueLocked] = useState(0);
    const [newChainId, setNewChainId] = useState("");
    const [chainId, setChainId] = useState(11155111);
    const [vaultAccount, setVaultAccount] = useState("");
    const [vaultManager, setVaultManager] = useState("");
    const [totalValueUSD, setTotalValueUSD] = useState(0);
    const [totalSupplyQuota, setTotalSupplyQuota] = useState(0);
    const [depositAmount, setDepositAmount] = useState(""); // New state for deposit amount

    const getVaultData = async () => {
        try {
            const chainId = await signer.getChainId();
            setChainId(parseInt(chainId));

            const abi = [
                "function vaultCounter() public view returns (uint256)",
                "function ownerOf(uint256 tokenId) public view virtual returns (address)",
                "function vaultHubChainAccounts(uint256 vaultId) public view returns (address)",
            ];
            const factoryContract = new ethers.Contract(
                HubChainFactories[Number(chainId)],
                abi,
                signer
            );

            const owner = await factoryContract.ownerOf(id);
            setVaultManager(owner);

            const vaultAddress = await factoryContract.vaultHubChainAccounts(id);
            setVaultAccount(vaultAddress);

            const abiVault = [
                "function getTotalValueInUSD() external view returns(uint256)",
                "function totalSupply() public view virtual returns (uint256)",
            ];

            const vaultContract = new ethers.Contract(vaultAddress, abiVault, signer);

            const totalValue = await vaultContract.getTotalValueInUSD();
            setTotalValueLocked(parseInt(totalValue._hex, 16));

            const totalSupply = await vaultContract.totalSupply();
            setTotalSupplyQuota(parseInt(totalSupply._hex, 16));
        } catch (err) {
            console.error("Failed to get vault data", err);
        }
    };

    useEffect(() => {
        getVaultData();
    }, [address, id]);

    const handleDeposit = async () => {
        try{
            const chainId = await signer.getChainId();
            console.log("chainId", chainId);

            const abi = [
                "function deposit(uint256 _amountInCurrencyToken) public"
            ]
            const vaultCountract = new ethers.Contract(
                vaultAccount,
                abi,
                signer
            );

            const tx = await vaultCountract.deposit(ethers.utils.parseEther(String(depositAmount)));

            window.open(`${explorers[Number(chainId)]}tx/${tx.hash}`);

        } catch(err){
            console.error("Failed to deposit", err);
        }

    }

    const handleApproveDeposit = async () => {
        try{
            const chainId = await signer.getChainId();
            console.log("chainId", chainId);

            const abi = [
                "function approve(address spender, uint256 amount) public returns (bool)"
            ]
            const currencyContract = new ethers.Contract(
                currencies[Number(chainId)],
                abi,
                signer
            );

            const tx = await currencyContract.approve(vaultAccount, ethers.utils.parseEther(String(depositAmount)));

            window.open(`${explorers[Number(chainId)]}tx/${tx.hash}`);



        } catch(err){
            console.error("Failed to approve deposit", err);
            
        }
    };

    const handleEvaluate = async () => {
        try{

            const abi = [
                "function evaluateTotalValue() public returns(uint256, uint256)"
            ]

            const vaultCountract = new ethers.Contract(
                vaultAccount,
                abi,
                signer
            );

            await vaultCountract.evaluateTotalValue();


        } catch(err){
            console.error("Failed to evaluate vault", err);
        }
    };

    const handleDeployToNetwork = async () => {
        if (!newChainId) {
            alert("Please enter a valid chain ID");
            return;
        }

        try {
            const chainIdToRegister = parseInt(newChainId, 10);

            const abi = [
                "function registerNewSpokeChain(uint256 vaultId, uint256 chainId) public payable"
            ];

            const vaultCountract = new ethers.Contract(
                vaultAccount,
                abi,
                signer
            );

            const tx = await vaultCountract.registerNewSpokeChain(id, chainIdToRegister, {value: ethers.utils.parseEther("0.01")});

            window.open(`https://testnet.layerzeroscan.com/tx/${tx.hash}`);

            
        } catch (err) {
            console.error("Failed to deploy to network", err);
            alert("Error deploying to network");
        }
    };


    return (
        <VaultPageStyle>
            <Header
                address={address}
                setAddress={setAddress}
                signer={signer}
                setSigner={setSigner}
                provider={provider}
                setProvider={setProvider}
            />

            <VaultInfo>
                <h2>Vault Information</h2>
                <p>
                    <strong>Vault Address: </strong>
                    <a
                        href={`${explorers[chainId]}address/${vaultAccount}`}
                        target="_blank"
                        rel="noopener noreferrer"
                    >
                        {vaultAccount}
                    </a>
                </p>
                <p>
                    <strong>Manager: </strong>
                    <a
                        href={`${explorers[chainId]}address/${vaultManager}`}
                        target="_blank"
                        rel="noopener noreferrer"
                    >
                        {vaultManager}
                    </a>
                </p>

                <TotalValueLocked>
                    <strong>Total Value Locked (TVL): </strong>${totalValueLocked.toLocaleString()}
                </TotalValueLocked>

                <TotalValueLocked>
                    <strong>Total Supply Quota:   {totalSupplyQuota}  </strong>
                </TotalValueLocked>

                    <TotalValueLocked>
                        <h4>Price: {totalSupplyQuota != 0 ? (totalValueLocked/totalSupplyQuota)*10**8 : 0 }</h4>
                    </TotalValueLocked>

                <DepositSection>
                    <h3>Deposit</h3>
                    <input
                        type="number"
                        placeholder="Enter deposit amount"
                        value={depositAmount}
                        onChange={(e) => setDepositAmount(e.target.value)}
                    />
                    <DepositButton onClick={handleApproveDeposit}>Approve Deposit</DepositButton>

                    <DepositButton onClick={handleDeposit}>Deposit</DepositButton>
                </DepositSection>

                <ButtonGroup>
                    <ActionButton onClick={handleEvaluate}>Evaluate Vault</ActionButton>
                </ButtonGroup>

                <DeploySection>
                    <h3>Deploy to a New Network</h3>
                    <DeployForm>
                        <input
                            type="number"
                            placeholder="Enter Chain ID"
                            value={newChainId}
                            onChange={(e) => setNewChainId(e.target.value)}
                        />
                        <DeployButton onClick={handleDeployToNetwork}>Deploy</DeployButton>
                    </DeployForm>
                </DeploySection>
            </VaultInfo>
        </VaultPageStyle>
    );
}

// Styled components
const VaultPageStyle = styled.div`
    padding: 20px;
`;

const VaultInfo = styled.div`
    margin-top: 20px;

    h2 {
        margin-bottom: 20px;
        text-align: center;
    }

    p {
        font-size: 16px;
        margin-bottom: 10px;

        a {
            color: #007bff;
            text-decoration: none;

            &:hover {
                text-decoration: underline;
            }
        }
    }
`;

const TotalValueLocked = styled.div`
    margin-top: 20px;
    font-size: 18px;
    font-weight: bold;
`;

const DepositSection = styled.div`
    margin-top: 20px;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 10px;

    input {
        padding: 10px;
        border: 1px solid #ccc;
        border-radius: 5px;
        width: 200px;
    }
`;

const DepositButton = styled.button`
    padding: 10px 20px;
    background-color: #28a745;
    color: white;
    border: none;
    border-radius: 5px;
    font-size: 16px;
    cursor: pointer;
    transition: background-color 0.2s, transform 0.2s;

    &:hover {
        background-color: #218838;
        transform: translateY(-2px);
    }

    &:active {
        transform: translateY(0);
    }
`;

const ButtonGroup = styled.div`
    display: flex;
    justify-content: center;
    gap: 20px;
    margin-top: 20px;
`;

const ActionButton = styled.button`
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

const DeploySection = styled.div`
    margin-top: 30px;
    text-align: center;
`;

const DeployForm = styled.div`
    display: flex;
    justify-content: center;
    align-items: center;
    gap: 10px;
    margin-top: 10px;

    input {
        padding: 10px;
        border: 1px solid #ccc;
        border-radius: 5px;
        width: 200px;
    }
`;

const DeployButton = styled.button`
    padding: 10px 20px;
    background-color: #28a745;
    color: white;
    border: none;
    border-radius: 5px;
    font-size: 16px;
    cursor: pointer;
    transition: background-color 0.2s, transform 0.2s;

    &:hover {
        background-color: #218838;
        transform: translateY(-2px);
    }

    &:active {
        transform: translateY(0);
    }
`;
