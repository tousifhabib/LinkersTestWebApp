import React from 'react';
import { Address } from '../types/address';

interface AddressTableProps {
    addresses: Address[];
    columnWidths?: { [key: string]: string };
}

const AddressTable: React.FC<AddressTableProps> = ({ addresses, columnWidths = {} }) => {
    const defaultWidths = {
        postal_code: '10%',
        prefecture: '10%',
        city: '15%',
        town_area: '15%',
        kyoto_street: '10%',
        block_number: '10%',
        business_name: '15%',
        business_address: '15%'
    };

    const getWidth = (key: string) => columnWidths[key] || defaultWidths[key as keyof typeof defaultWidths];

    return (
        <div className="table-container">
            <div className="scan-lines"></div>
            <table className="address-table">
                <thead>
                <tr>
                    <th style={{ width: getWidth('postal_code') }}>郵便番号</th>
                    <th style={{ width: getWidth('prefecture') }}>都道府県</th>
                    <th style={{ width: getWidth('city') }}>市区町村</th>
                    <th style={{ width: getWidth('town_area') }}>町域</th>
                    <th style={{ width: getWidth('kyoto_street') }}>京都通り名</th>
                    <th style={{ width: getWidth('block_number') }}>字丁目</th>
                    <th style={{ width: getWidth('business_name') }}>事業所名</th>
                    <th style={{ width: getWidth('business_address') }}>事業所住所</th>
                </tr>
                </thead>
                <tbody>
                {addresses.map((address, index) => (
                    <tr key={index}>
                        <td>{address.postal_code}</td>
                        <td>{address.prefecture}</td>
                        <td>{address.city}</td>
                        <td>{address.town_area}</td>
                        <td>{address.kyoto_street || '-'}</td>
                        <td>{address.block_number || '-'}</td>
                        <td>{address.business_name || '-'}</td>
                        <td>{address.business_address || '-'}</td>
                    </tr>
                ))}
                </tbody>
            </table>
        </div>
    );
};

export default AddressTable;
