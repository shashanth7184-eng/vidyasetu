export type AppRole = "admin" | "teacher" | "volunteer" | "parent";

export interface Profile {
  id: string;
  full_name: string;
  role: AppRole;
  phone: string | null;
  school_id: string | null;
  village: string | null;
}

export type AuthStatus =
  | "loading"
  | "unconfigured"
  | "signed-out"
  | "signed-in"
  | "profile-missing"
  | "error";
