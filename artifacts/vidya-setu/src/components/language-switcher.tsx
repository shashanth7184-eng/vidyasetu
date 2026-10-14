import { languages } from "@/lib/i18n";
import { useLanguage } from "@/hooks/use-language";

export function LanguageSwitcher() {
  const { language, setLanguage, t } = useLanguage();

  return (
    <label className="vs-language-control">
      <span className="sr-only">{t("languageLabel")}</span>
      <select
        className="vs-language-select"
        aria-label={t("languageLabel")}
        data-testid="select-language"
        value={language}
        onChange={(event) => setLanguage(event.target.value as "en" | "hi" | "te")}
      >
        {languages.map((option) => (
          <option key={option.code} value={option.code}>
            {option.nativeLabel}
          </option>
        ))}
      </select>
    </label>
  );
}
