import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";
import type { Session } from "@supabase/supabase-js";
import { isSupabaseConfigured, supabase } from "@/lib/supabase";
import type { AppRole, AuthStatus, Profile } from "@/types/auth";

interface AuthContextValue {
  status: AuthStatus;
  profile: Profile | null;
  error: string | null;
  requestCode: (identifier: string) => Promise<void>;
  verifyCode: (identifier: string, token: string) => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

const profileFields = "id, full_name, role, phone, school_id, village";
const validRoles: AppRole[] = ["admin", "teacher", "volunteer", "parent"];

function isProfile(value: unknown): value is Profile {
  if (!value || typeof value !== "object") return false;
  const record = value as Record<string, unknown>;
  return (
    typeof record.id === "string" &&
    typeof record.full_name === "string" &&
    typeof record.role === "string" &&
    validRoles.includes(record.role as AppRole) &&
    (typeof record.phone === "string" || record.phone === null) &&
    (typeof record.school_id === "string" || record.school_id === null) &&
    (typeof record.village === "string" || record.village === null)
  );
}

function readableError(error: unknown): string {
  if (error instanceof Error && error.message) return error.message;
  return "Something went wrong. Please try again.";
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [status, setStatus] = useState<AuthStatus>(
    isSupabaseConfigured ? "loading" : "unconfigured",
  );
  const [profile, setProfile] = useState<Profile | null>(null);
  const [error, setError] = useState<string | null>(null);
  const profileRequestId = useRef(0);

  const loadProfile = useCallback(async (session: Session | null) => {
    const requestId = ++profileRequestId.current;
    setError(null);

    if (!session) {
      setProfile(null);
      setStatus("signed-out");
      return;
    }

    if (!supabase) {
      setProfile(null);
      setStatus("unconfigured");
      return;
    }

    setStatus("loading");
    const { data, error: profileError } = await supabase
      .from("profiles")
      .select(profileFields)
      .eq("id", session.user.id)
      .maybeSingle();

    if (requestId !== profileRequestId.current) return;

    if (profileError) {
      setProfile(null);
      setError(profileError.message);
      setStatus("error");
      return;
    }

    if (!isProfile(data)) {
      setProfile(null);
      setStatus("profile-missing");
      return;
    }

    setProfile(data);
    setStatus("signed-in");
  }, []);

  useEffect(() => {
    if (!supabase) {
      setStatus("unconfigured");
      return;
    }

    let mounted = true;
    void supabase.auth.getSession().then(({ data, error: sessionError }) => {
      if (!mounted) return;
      if (sessionError) {
        setError(sessionError.message);
        setStatus("error");
        return;
      }
      void loadProfile(data.session);
    });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      if (mounted) void loadProfile(session);
    });

    return () => {
      mounted = false;
      profileRequestId.current += 1;
      subscription.unsubscribe();
    };
  }, [loadProfile]);

  const requestCode = useCallback(async (identifier: string) => {
    if (!supabase) throw new Error("Supabase is not configured for this app.");
    const value = identifier.trim();
    if (!value) throw new Error("Enter an email address or phone number.");

    const isEmail = value.includes("@");
    const { error: otpError } = isEmail
      ? await supabase.auth.signInWithOtp({
          email: value,
          options: {
            shouldCreateUser: true,
            emailRedirectTo: window.location.origin,
          },
        })
      : await supabase.auth.signInWithOtp({
          phone: value,
          options: { shouldCreateUser: true },
        });

    if (otpError) throw otpError;
  }, []);

  const verifyCode = useCallback(
    async (identifier: string, token: string) => {
      if (!supabase) throw new Error("Supabase is not configured for this app.");
      const value = identifier.trim();
      const code = token.trim();
      if (!value || !code) throw new Error("Enter your email or phone and the code.");

      const isEmail = value.includes("@");
      const result = isEmail
        ? await supabase.auth.verifyOtp({
            email: value,
            token: code,
            type: "email",
          })
        : await supabase.auth.verifyOtp({
            phone: value,
            token: code,
            type: "sms",
          });

      if (result.error) throw result.error;
      if (!result.data.session) {
        throw new Error("The code was accepted, but no session was returned.");
      }
      await loadProfile(result.data.session);
    },
    [loadProfile],
  );

  const signOut = useCallback(async () => {
    if (!supabase) return;
    const { error: signOutError } = await supabase.auth.signOut();
    if (signOutError) throw signOutError;
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      status,
      profile,
      error,
      requestCode: async (identifier) => {
        try {
          await requestCode(identifier);
        } catch (requestError) {
          throw new Error(readableError(requestError));
        }
      },
      verifyCode: async (identifier, token) => {
        try {
          await verifyCode(identifier, token);
        } catch (verifyError) {
          throw new Error(readableError(verifyError));
        }
      },
      signOut: async () => {
        try {
          await signOut();
        } catch (signOutError) {
          throw new Error(readableError(signOutError));
        }
      },
    }),
    [status, profile, error, requestCode, verifyCode, signOut],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error("useAuth must be used within an AuthProvider.");
  return context;
}
