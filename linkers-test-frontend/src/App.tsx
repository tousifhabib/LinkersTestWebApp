import React from 'react';
import AddressSearch from './components/AddressSearch';
import './App.css';

const App: React.FC = () => {
    return (
        <div className="App cyberpunk-app">
            <header className="cyberpunk-header">
                <h1 className="neon-text">住所検索システム</h1>
            </header>
            <AddressSearch />
        </div>
    );
};

export default App;
