% Lista delle AZIONI da elaborare
lista_azioni = {'A2A.MI', 'AMP.MI', 'BC.MI', 'BFG.MI', 'BMED.MI', 'BPE.MI', ...
    'BZU.MI', 'CIR.MI', 'CLI.MI', 'CMTL', 'CPR.MI', 'CULT.MI', 'D.MI', 'DAN.MI', ...
    'DIA.MI', 'DLG.MI', 'ENEL.MI', 'ENI.MI', 'ENV.MI', 'FBK.MI', 'FCT.MI', 'FF.MI', ...
    'G.MI', 'HER.MI', 'ICOS.MI', 'IG.MI', 'IP.MI', 'IRE.MI', 'ISP.MI', 'ITM.MI', ...
    'IVG.MI', 'IWB.MI', 'LDO.MI', 'LON.MI', 'LTMC.MI', 'MARR.MI', 'MASI.MI', 'MB.MI', ...
    'MN.MI', 'MONC.MI', 'MS.MI', 'NWL.MI', 'ORS.MI', 'OS.MI', 'PHN.MI', 'PIRC.MI', ...
    'PRY.MI', 'PST.MI', 'RACE', 'REC.MI', 'REY.MI', 'SES.MI', 'SPM.MI', 'SRG.MI', ...
    'STLA', 'STM', 'TEN.MI', 'TIME.MI', 'TIT.MI', 'TPRO.MI', 'TRN.MI', 'TSL.MI', ...
    'UBM.MI', 'UCG.MI', 'VLS.MI', 'AAPL', 'ADBE', 'AGMH', 'AMD', 'AMGN', 'AMZN', ...
    'AVGO', 'BCDA', 'BKNG', 'CHTR', 'CMCSA', 'COST', 'CSCO', 'GOOGL', 'HON', 'INTC', ...
    'LIN', 'MELI', 'META', 'MSFT', 'MSTR', 'NFLX', 'NVDA', 'PEP', 'PYPL', 'QQQ', ...
    'RGLS', 'SHOP', 'SLSN', 'TMUS', 'TSLA', 'TXN', 'UPC', 'ABBV', 'ABT', 'ACN', ...
    'AXP', 'BA', 'BAC', 'BLK', 'BRK-A', 'BX', 'C', 'CAT', 'CL', 'CRM', 'CVX', 'DE', ...
    'DIS', 'DOW', 'DUK', 'GE', 'GS', 'HD', 'HIMS', 'HPQ', 'IBM', 'JNJ', 'JPM', 'KO', ...
    'LLY', 'MA', 'MCD', 'MMM', 'MRK', 'MS', 'NKE', 'NVO', 'ORCL', 'PFE', 'PG', 'PGR', ...
    'PLD', 'PM', 'SCHW', 'SLB', 'SPGI', 'SPOT', 'T', 'TJX', 'TMO', 'TSM', 'UBER', ...
    'UNH', 'UNP', 'V', 'VZ', 'WFC', 'WMT', 'XOM'};

% Cartella di output per i grafici
output_dir = 'Grafici_AZIONI';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Inizializza tabella dei risultati
riepilogo = table('Size', [0, 6], ...
    'VariableTypes', {'string', 'double', 'double', 'double', 'datetime', 'datetime'}, ...
    'VariableNames', {'AZIONE', 'UltimoPrezzo', 'UltimaSMA200', 'UltimaRegressione', 'DataInizio', 'DataFine'});

% Inizializza tabella degli errori
errori = table('Size', [0, 2], ...
    'VariableTypes', {'string', 'string'}, ...
    'VariableNames', {'AZIONE', 'Errore'});

% Inizia ciclo su ogni AZIONE
for i = 1:length(lista_azioni)
    azione = lista_azioni{i};
    file_csv = fullfile('Dati', [azione '_dati.csv']);

    % Verifica esistenza file
    if ~isfile(file_csv)
        fprintf('⚠️ File %s non trovato.\n', file_csv);
        errori = [errori; {azione, 'File non trovato'}];
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
        errori = [errori; {azione, sprintf('Errore lettura file: %s', err.message)}];
        continue;
    end

    % Controllo colonna chiusura
    nome_colonna_chiusura = [azione '.Close'];
    if ~ismember(nome_colonna_chiusura, dati.Properties.VariableNames)
        fprintf('❌ Colonna %s mancante in %s.\n', nome_colonna_chiusura, file_csv);
        errori = [errori; {azione, 'Colonna .Close mancante'}];
        continue;
    end

    % Estrai dati
    try
        date = dati.Date;
        prezzi_chiusura = dati.(nome_colonna_chiusura);

        % Validazione dati
        if numel(prezzi_chiusura) < 200
            fprintf('⚠️ AZIONE %s ha meno di 200 dati. Saltato.\n', azione);
            errori = [errori; {azione, 'Dati insufficienti (<200)'}];
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
        nuova_riga = {azione, ultimo_prezzo, ultima_sma_200, ultima_regressione, data_inizio, data_fine};
        riepilogo = [riepilogo; nuova_riga];

        % Grafico
        figure('Visible', 'off', 'Name', sprintf('Andamento %s', azione));
        hold on;
        plot(date, prezzi_chiusura, 'g-', 'LineWidth', 1.5, ...
            'DisplayName', sprintf('Prezzo di chiusura (ultimo: %.2f EUR)', ultimo_prezzo));
        plot(date, regressione, 'b-', 'LineWidth', 1.5, ...
            'DisplayName', sprintf('Regressione lineare (ultimo: %.2f)', ultima_regressione));
        plot(date, sma_200, 'r-', 'LineWidth', 1.5, ...
            'DisplayName', sprintf('SMA 200 (ultimo: %.2f)', ultima_sma_200));
        hold off;
        xlabel('Data');
        ylabel('Prezzo di chiusura (EUR)');
        title(sprintf('Andamento %s con regressione e SMA 200', azione));
        legend('show', 'Location', 'best');
        grid on;

        % Salva grafico
        filename_png = fullfile(output_dir, sprintf('Andamento_%s.png', azione));
        exportgraphics(gcf, filename_png, 'Resolution', 100);
        close(gcf);

        % Output console
        fprintf('✅ %s processato correttamente.\n', azione);

    catch err
        fprintf('❌ Errore nel processare %s: %s\n', azione, err.message);
        errori = [errori; {azione, sprintf('Errore elaborazione: %s', err.message)}];
        continue;
    end
end

% Salva riepilogo e errori
writetable(riepilogo, 'riepilogo_azioni.csv');
writetable(errori, 'azioni_non_processate.csv');

fprintf('\n📝 Riepilogo salvato in: riepilogo_azioni.csv\n');
fprintf('🚫 AZIONI non processate salvate in: azioni_non_processate.csv\n');
fprintf('🏁 Fine elaborazione di tutte le AZIONI.\n');
