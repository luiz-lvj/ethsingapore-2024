import { BrowserRouter, Route, Routes } from "react-router-dom";
import Home from "./components/Home";
import './styles/App.css';
import { useState } from "react";
import VaultPage from "./components/Vault";


function App() {

  const [address, setAddress] = useState("");
  const [signer, setSigner] = useState(null);
  const [provider, setProvider] = useState(null);


  return (
    <BrowserRouter>
      <div className="app-container">
        <main>
          <Routes>
            <Route path="/" element={<Home    
              address={address}
              setAddress={setAddress}
              signer={signer}
              setSigner={setSigner}
              provider={provider}
              setProvider={setProvider}

            
            />} />

            <Route path="/vault/:id" element={<VaultPage
              address={address}
              setAddress={setAddress}
              signer={signer}
              setSigner={setSigner}
              provider={provider}
              setProvider={setProvider}
            />} />
            
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  );
}

export default App;
