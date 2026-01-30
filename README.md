# dukakiganjani

A new Flutter project.

## Supabase Authentication Implementation

This app uses Supabase for authentication with a custom registration flow for owners.

### Authentication Flow

#### Owner Registration
- **Email Format**: Uses fake emails in the format `{phone}@dukakiganjani.com` (e.g., `712345678@dukakiganjani.com`)
- **Password**: Uses the 4-digit PIN in format `pin@phone` (e.g., `1234@712345678`)
- **Phone Storage**: Stores phone numbers without `+255` prefix to fit VARCHAR(12) constraint
- **Profile Creation**: Automatically creates a profile in the `owner_profiles` table upon successful registration

#### Owner Login
- **Authentication**: Uses the same fake email and password format as registration
- **PIN Input**: 4-digit PIN entered via individual input boxes with auto-focus navigation
- **Validation**: Ensures both phone number and complete PIN are provided before attempting login

#### Database Schema
```sql
CREATE TABLE owner_profiles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name text NOT NULL,
    email text,
    phone varchar(12) NOT NULL UNIQUE,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);
```

#### Supabase Configuration
- **URL**: https://qzeeggpkjqoqwqskxotq.supabase.co
- **Anon Key**: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF6ZWVnZ3BranFvcXdxc2t4b3RxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc2MjA2MTIsImV4cCI6MjA4MzE5NjYxMn0.V55wn1GdjAMTaI1RqkEd6aW9KLlanEarU0S4kmXwirw

#### Stores Management
- **User-Specific Stores**: Each owner can view and manage only their own stores
- **Real-time Data**: Stores are loaded from and saved to the Supabase database
- **Full CRUD Operations**: Create, Read, Update, Delete store functionality
- **Add Store**: Create new stores with name, type, location, and description
- **Edit Store**: Update existing store information
- **Delete Store**: Remove stores with confirmation dialog
- **Activate/Deactivate Store**: Toggle store status (Active/Inactive) to show/hide from customers
- **Loading States**: Visual feedback during all operations

#### Database Tables

##### owner_profiles
```sql
CREATE TABLE owner_profiles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name text NOT NULL,
    email text,
    phone varchar(12) NOT NULL UNIQUE,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);
```

##### stores
```sql
create table public.stores (
  id uuid not null default extensions.uuid_generate_v4 (),
  owner_id uuid not null,
  name text not null,
  type text not null,
  description text null,
  location text null,
  status text not null default 'Active'::text,
  currency text null default 'TZS'::text,
  country text null default 'Tanzania'::text,
  last_sync_at timestamp with time zone null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint stores_pkey primary key (id),
  constraint stores_owner_id_fkey foreign KEY (owner_id) references auth.users (id) on delete CASCADE,
  constraint stores_status_check check (
    (
      status = any (array['Active'::text, 'Inactive'::text])
    )
  )
) TABLESPACE pg_default;
```

### Implementation Details

1. **Supabase Initialization**: Configured in `lib/main.dart`
2. **Service Layer**: `lib/services/supabase_service.dart` handles auth and store operations
3. **Authentication**: `lib/auth/owner_register.dart` and `lib/auth/owner_login.dart`
4. **Store Management**: `lib/pages/store_list.dart` with full CRUD operations
5. **Data Models**: `lib/model/store.dart` for type-safe data handling
6. **Email Generation**: Phone number creates unique `{phone}@dukakiganjani.com` emails
7. **Password Security**: Uses `pin@phone` format for enhanced security

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
