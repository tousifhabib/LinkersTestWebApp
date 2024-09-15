import React from 'react';

interface SearchInputProps {
    value: string;
    onChange: (value: string) => void;
}

const SearchInput: React.FC<SearchInputProps> = ({ value, onChange }) => {
    return (
        <input
            type="text"
            placeholder="住所を入力してください..."
            value={value}
            onChange={(e) => onChange(e.target.value)}
            className="search-input"
        />
    );
};

export default SearchInput;
