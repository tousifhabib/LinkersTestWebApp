import React, { useState, useEffect, useCallback } from 'react';
import { debounce } from 'lodash';
import SearchInput from './SearchInput';
import AddressTable from './AddressTable';
import { searchAddresses, buildIndex } from '../services/addressService';
import { Address } from '../types/address';

const AddressSearch: React.FC = () => {
    const [query, setQuery] = useState('');
    const [addresses, setAddresses] = useState<Address[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [indexBuildMessage, setIndexBuildMessage] = useState<string | null>(null);

    const handleSearch = useCallback(
        debounce(async (searchQuery: string) => {
            if (!searchQuery) {
                setAddresses([]);
                return;
            }

            setIsLoading(true);
            setError(null);

            try {
                const result = await searchAddresses(searchQuery);
                setAddresses(result);
            } catch (err) {
                setError(err instanceof Error ? err.message : '予期せぬエラーが発生しました');
                console.error('住所の取得中にエラーが発生しました:', err);
            } finally {
                setIsLoading(false);
            }
        }, 300),
        []
    );

    const handleBuildIndex = async () => {
        setIsLoading(true);
        setError(null);
        setIndexBuildMessage(null);

        try {
            const message = await buildIndex();
            setIndexBuildMessage(message);
        } catch (err) {
            setError(err instanceof Error ? err.message : '予期せぬエラーが発生しました');
            console.error('インデックスの構築中にエラーが発生しました:', err);
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        handleSearch(query);
    }, [query, handleSearch]);

    return (
        <>
            <button className="build-index-button" onClick={handleBuildIndex} disabled={isLoading}>
                インデックス構築
            </button>
            <div className="cyberpunk-main">
                <div className="address-search">
                    <SearchInput value={query} onChange={setQuery} />
                    {error && <div className="error-message">{error}</div>}
                    {indexBuildMessage && <div className="success-message">{indexBuildMessage}</div>}
                    {isLoading ? (
                        <p style={{ color: 'var(--neon-blue)', fontFamily: 'Orbitron' }}>ニューラルネットワークをスキャン中...</p>
                    ) : (
                        <AddressTable addresses={addresses} />
                    )}
                </div>
            </div>
        </>
    );
};

export default AddressSearch;
