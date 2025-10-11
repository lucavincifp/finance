% Lista delle MATERIE PRIME da elaborare
lista_materie = {'GC-F', 'SI-F', 'HG-F', 'CL-F', 'BZ-F', 'NG-F'};

% Cartella di output per i grafici
output_dir = 'Grafici_MATERIE';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Inizializza tabella dei risultati
riepilogo = table('Size', [0, 6], ...
    'VariableTypes', {'string', 'double', 'double', 'double', 'datetime', 'datetime'}, ...
    'VariableNames', {'MATERIA', 'UltimoPrezzo', 'UltimaSMA200', 'UltimaRegressione', 'DataInizio', 'DataFine'});

% Inizializza tabella degli errori
errori = table('Size', [0, 2], ...
    'VariableTypes', {'string', 'string'}, ...
    'VariableNames', {'MATERIA', 'Errore'});

% Inizia ciclo su ogni MATERIA PRIMA
for i = 1:length(lista_materie)
    materia = lista_materie{i};
    file_csv = fullfile('Dati', [materia '_dati.csv']);

    % Verifica esistenza file
    if ~isfile(file_csv)
        fprintf('⚠️ File %s non trovato.\n', file_csv);
        errori = [errori; {materia, 'File non trovato'}];
        continue;
    end

    % Carica i dati
    try
        opts = detectImportOptions(file_csv, 'Delimiter', ',');
        opts = setvartype(opts, 'Date', 'datetime');
        opts = setvaropts(opts, 'Date', 'InputFormat', 'yyyy-MM-dd');
        opts.VariableNamingRule = 'preserve';
        dati = readtable(file_csv, opts);
    catch err
        fprintf('❌ Errore nel leggere %s: %s\n', file_csv, err.message);
        errori = [errori; {materia, sprintf('Errore lettura file: %s', err.message)}];
        continue;
    end

    % Controllo colonna chiusura
    nome_colonna_chiusura = [materia '.Close'];
    if ~ismember(nome_colonna_chiusura, dati.Properties.VariableNames)
        fprintf('❌ Colonna %s mancante in %s.\n', nome_colonna_chiusura, file_csv);
        errori = [errori; {materia, 'Colonna .Close mancante'}];
        continue;
    end

    % Estrai dati
    try
        date = dati.Date;
        prezzi_chiusura = dati.(nome_colonna_chiusura);

        % Validazione dati
        if numel(prezzi_chiusura) < 200
            fprintf('⚠️ MATERIA %s ha meno di 200 dati. Saltato.\n', materia);
            errori = [errori; {materia, 'Dati insufficienti (<200)'}];
            continue;
        end

        % Calcoli
        sma_window = 200;
        sma_200 = movmean(prezzi_chiusura, sma_window);
        x = (1:length(prezzi_chiusura))';
        y = prezzi_chiusura;
        coeff = polyfit(x, y, 1);
        regressione = polyval(coeff, x);

        % Estrai ultimi valori
        ultimo_prezzo = prezzi_chiusura(end);
        ultima_regressione = regressione(end);
        ultima_sma_200 = sma_200(end);
        data_inizio = min(date);
        data_fine = max(date);

        % Salva riepilogo
        nuova_riga = {materia, ultimo_prezzo, ultima_sma_200, ultima_regressione, data_inizio, data_fine};
        riepilogo = [riepilogo; nuova_riga];

        % Grafico
        figure('Visible', 'off', 'Name', sprintf('Andamento %s', materia));
        hold on;
        plot(date, prezzi_chiusura, 'g-', 'LineWidth', 1.5, ...
            'DisplayName', sprintf('Prezzo di chiusura (ultimo: %.2f EUR)', ultimo_prezzo));
        %plot(date, regressione, 'b-', 'LineWidth', 1.5, ...
        %    'DisplayName', sprintf('Regressione lineare (ultimo: %.2f)', ultima_regressione));
        %plot(date, sma_200, 'r-', 'LineWidth', 1.5, ...
        %    'DisplayName', sprintf('SMA 200 (ultimo: %.2f)', ultima_sma_200));
        hold off;
        xlabel('Data');
        ylabel('Prezzo di chiusura (EUR)');
        %title(sprintf('Andamento %s con regressione e SMA 200', materia));
        title(sprintf('Andamento %s', materia));
        legend('show', 'Location', 'best');
        grid on;

        % Salva grafico
        filename_png = fullfile(output_dir, sprintf('Andamento_%s.png', materia));
        exportgraphics(gcf, filename_png, 'Resolution', 100);
        close(gcf);

        % Output console
        fprintf('✅ %s processato correttamente.\n', materia);

    catch err
        fprintf('❌ Errore nel processare %s: %s\n', materia, err.message);
        errori = [errori; {materia, sprintf('Errore elaborazione: %s', err.message)}];
        continue;
    end
end

% Salva riepilogo e errori
writetable(riepilogo, 'riepilogo_materie.csv');
writetable(errori, 'materie_non_processate.csv');

fprintf('\n📝 Riepilogo salvato in: riepilogo_materie.csv\n');
fprintf('🚫 MATERIE PRIME non processate salvate in: materie_non_processate.csv\n');
fprintf('🏁 Fine elaborazione di tutte le MATERIE PRIME.\n');
