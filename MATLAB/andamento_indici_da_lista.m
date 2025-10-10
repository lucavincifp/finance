% Lista degli INDICI da elaborare
lista_indici = {'DJI', 'FTSE', 'FTSEMIB.MI', 'GDAXI', 'GSPC', 'HSI', 'IXIC', ...
    'N225', 'NYA', 'STOXX50E', 'VIX', 'XAX', 'XDE', 'MOVE', 'SPX'};

% Cartella di output per i grafici
output_dir = 'Grafici_INDICI';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Inizializza tabella dei risultati
riepilogo = table('Size', [0, 6], ...
    'VariableTypes', {'string', 'double', 'double', 'double', 'datetime', 'datetime'}, ...
    'VariableNames', {'Indice', 'UltimoPrezzo', 'UltimaSMA200', 'UltimaRegressione', 'DataInizio', 'DataFine'});

% Inizializza tabella degli errori
errori = table('Size', [0, 2], ...
    'VariableTypes', {'string', 'string'}, ...
    'VariableNames', {'Indice', 'Errore'});

% Inizia ciclo su ogni indice
for i = 1:length(lista_indici)
    indice = lista_indici{i};
    file_csv = fullfile('Dati', [indice '_dati.csv']);

    % Verifica esistenza file
    if ~isfile(file_csv)
        fprintf('⚠️  File %s non trovato.\n', file_csv);
        errori = [errori; {indice, 'File non trovato'}];
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
        errori = [errori; {indice, sprintf('Errore lettura file: %s', err.message)}];
        continue;
    end

    % Controllo colonna chiusura
    nome_colonna_chiusura = [indice '.Close'];
    if ~ismember(nome_colonna_chiusura, dati.Properties.VariableNames)
        fprintf('❌ Colonna %s mancante in %s.\n', nome_colonna_chiusura, file_csv);
        errori = [errori; {indice, 'Colonna .Close mancante'}];
        continue;
    end

    % Estrai dati
    try
        date = dati.Date;
        prezzi_chiusura = dati.(nome_colonna_chiusura);

        % Validazione dati
        if numel(prezzi_chiusura) < 200
            fprintf('⚠️  Indice %s ha meno di 200 dati. Saltato.\n', indice);
            errori = [errori; {indice, 'Dati insufficienti (<200)'}];
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
        nuova_riga = {indice, ultimo_prezzo, ultima_sma_200, ultima_regressione, data_inizio, data_fine};
        riepilogo = [riepilogo; nuova_riga];

        % Grafico
        figure('Visible', 'off', 'Name', sprintf('Andamento %s', indice));
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
        %title(sprintf('Andamento %s con regressione e SMA 200', indice));
        title(sprintf('Andamento %s', indice));
        legend('show', 'Location', 'best');
        grid on;

        % Salva grafico
        filename_png = fullfile(output_dir, sprintf('Andamento_%s.png', indice));
        exportgraphics(gcf, filename_png, 'Resolution', 100);
        close(gcf);

        % Output console
        fprintf('✅ %s processato correttamente.\n', indice);

    catch err
        fprintf('❌ Errore nel processare %s: %s\n', indice, err.message);
        errori = [errori; {indice, sprintf('Errore elaborazione: %s', err.message)}];
        continue;
    end
end

% Salva riepilogo e errori
writetable(riepilogo, 'riepilogo_indici.csv');
writetable(errori, 'indici_non_processati.csv');

fprintf('\n📝 Riepilogo salvato in: riepilogo_indici.csv\n');
fprintf('🚫 Indici non processati salvati in: indici_non_processati.csv\n');
fprintf('🏁 Fine elaborazione di tutti gli indici.\n');
