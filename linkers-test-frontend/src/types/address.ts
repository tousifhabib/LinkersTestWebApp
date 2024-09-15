export interface Address {
    postal_code: string;
    prefecture: string;
    city: string;
    town_area: string;
    kyoto_street: string | null;
    block_number: string | null;
    business_name: string | null;
    business_address: string | null;
}
