import axios from 'axios';
import { Address } from '../types/address';

const API_BASE_URL = 'http://localhost:3000/api/v1';

export const searchAddresses = async (query: string): Promise<Address[]> => {
    try {
        const response = await axios.get(`${API_BASE_URL}/addresses`, {
            params: { query },
        });
        return response.data;
    } catch (error) {
        if (axios.isAxiosError(error)) {
            if (error.response?.status === 400) {
                throw new Error(error.response.data.error || 'Bad request');
            } else if (error.response?.status === 500) {
                throw new Error(error.response.data.error || 'Internal server error');
            }
        }
        throw new Error('An unexpected error occurred');
    }
};

export const buildIndex = async (): Promise<string> => {
    try {
        const response = await axios.post(`${API_BASE_URL}/build_index`);
        return response.data.message;
    } catch (error) {
        if (axios.isAxiosError(error) && error.response?.status === 500) {
            throw new Error(error.response.data.error || 'Internal server error');
        }
        throw new Error('An unexpected error occurred');
    }
};
