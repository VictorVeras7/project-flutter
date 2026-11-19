# Rango (Flutter)

App de delivery Rango em Flutter, para Android e iOS. É o lado Flutter do TCC que compara Kotlin Multiplatform e Flutter. O lado KMP está em [project-kmp](https://github.com/VictorVeras7/project-kmp).

O app segue o mesmo protótipo e usa o mesmo back-end do lado KMP. As features são feitas na mesma ordem, para comparar uma a uma.

## Registro de uso de IA e métricas de desenvolvimento (TCC)

Este repositório usa um Issue Form para registrar, por feature, o uso de IA e as métricas objetivas e subjetivas de desenvolvimento, comparando KMP e Flutter.

### Fluxo de uso (resumo)

1. **Antes de começar a feature:** abra uma issue nova a partir do template "Registro de Feature (KMP/Flutter + uso de IA)" (**Issues → New issue** no GitHub). Preencha framework, nome da feature e a hora de início.
2. **Durante o desenvolvimento:**
   - Marque cada commit relacionado com o trailer padronizado:
     ```bash
     git commit -m "feat(escopo): mensagem do commit" -m "AI-Extent: assistido"
     ```
     Valores possíveis para `AI-Extent`: `gerado`, `assistido`, `manual`.
   - Conte os prompts usados (pode ser um comentário na própria issue).
3. **Ao terminar a feature:** edite a issue e preencha a seção "Ao finalizar": tempo total, número de prompts, LOC IA/manual (via `git log`), dificuldade percebida, confiança no código gerado e se houve retrabalho relevante. Feche a issue. Fechar = registro completo daquela feature.
4. **Periodicamente** (a cada 3 ou 4 features): exporte as issues fechadas em CSV (via GitHub UI ou API) para consolidar o dataset usado no TCC.

### Calculando LOC por AI-Extent

```bash
# Lista os commits marcados como "gerado"
git log --grep="AI-Extent: gerado" --oneline

# Soma das linhas adicionadas e removidas desses commits
git log --grep="AI-Extent: gerado" --numstat --format=
```

### Pontos de plataforma

No Flutter, conta como ponto de plataforma o código escrito à mão em Kotlin/Swift ou o uso de `MethodChannel`. Plugins prontos do pub.dev não contam, mas são citados nas observações da issue.
