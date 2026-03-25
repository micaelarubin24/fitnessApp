import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import { Button } from "@/components/ui/button";

export default async function LoginPage() {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (user) redirect("/dashboard");

  async function loginConGoogle() {
    "use server";
    const supabase = createClient();
    const { data } = await supabase.auth.signInWithOAuth({
      provider: "google",
      options: {
        redirectTo: `${process.env.NEXT_PUBLIC_SITE_URL}/auth/callback`,
      },
    });
    if (data.url) redirect(data.url);
  }

  return (
    <main className="flex min-h-screen items-center justify-center">
      <div className="flex flex-col items-center gap-6">
        <h1 className="text-2xl font-bold">Trainer App</h1>
        <form action={loginConGoogle}>
          <Button type="submit">Continuar con Google</Button>
        </form>
      </div>
    </main>
  );
}
