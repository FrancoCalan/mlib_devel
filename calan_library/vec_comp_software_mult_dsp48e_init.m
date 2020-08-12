function vec_comp_software_mult_dsp48e_init(blk, varargin)
    % Usage: vec_comp_software_mult_dsp48e_init(gcb, 'var')
    % Sequentially multiplies complex input data with data stored in bram. 
    % Used to load calibration constant for digital calibration systems.
    % The bram data is meant to be loaded from an external computer. 
    % The multipliers are implemented with DSP48E.
    %
    % Valid 'var' names are:
    % din_n_bits = bitwidth of real part of input (= imaginary part)
    % din_bin_pt = binary point of real part of input (= imaginary part)
    % bram_n_bits = bitwidth of real part of bram constants (= imaginary part)
    % bram_bin_pt = binary point of real part of bram constants (= imaginary part)
    % log2_vec_len = log2 of vector length, equal to bram memory size
    % dout_n_bits = bitwidth of real part of output (= imaginary part)
    % dout_bin_pt = binary point of real part of output (= imaginary part)
    % quantization = flag: 1: Truncate, 2: Round (unbiased: +/- Inf)
    % overflow = flag: 1: Wrap, 2: Saturate, 3: Flag as error

    if same_state(blk, varargin{:}), return, end
    munge_block(blk, varargin{:});

    din_n_bits         = get_var('din_n_bits', varargin{:});
    din_bin_pt         = get_var('din_bin_pt', varargin{:});
    bram_n_bits_popup  = get_var('bram_n_bits_popup', varargin{:});
    bram_bin_pt        = get_var('bram_bin_pt', varargin{:});
    log2_vec_len       = get_var('log2_vec_len', varargin{:});
    dout_n_bits        = get_var('dout_n_bits', varargin{:});
    dout_bin_pt        = get_var('dout_bin_pt', varargin{:});
    quantization       = get_var('quantization', varargin{:});
    overflow           = get_var('overflow', varargin{:});

    bram_n_bits = 2^(2+bram_n_bits_popup);
    bram_addr_width = log2_vec_len;
    
    % set bram addr width to minimum allowed by Xilinx tools
    if bram_addr_width + log2(bram_n_bits)  < 15,
        bram_addr_width = 15 - log2(bram_n_bits);
    end
    
    delete_lines(blk);

    if din_n_bits == 0 || dout_n_bits == 0,
        clean_blocks(blk);
        set_param(blk,'AttributesFormatString','');
        save_state(blk, varargin{:});
        return;
    end
    
    if (din_n_bits < din_bin_pt),
        errordlg('Number of bits for input must be greater than binary point position.'); return; end
    if (bram_n_bits < bram_bin_pt),
        errordlg('Number of bits for bram must be greater than binary point position.'); return; end
    if (dout_n_bits < dout_bin_pt),
        errordlg('Number of bits for output must be greater than binary point position.'); return; end

    % block generation
    reuse_block(blk, 'sync', 'simulink/Sources/In1', ...
        'Port', '1', ...
        'Position', [540 98 570 112]);
        
    reuse_block(blk, 'din', 'simulink/Sources/In1', ...
        'Port', '2', ...
        'Position', [540 308 570 322]);

    reuse_block(blk, 'Counter', 'xbsIndex_r4/Counter', ...
        'n_bits', num2str(log2_vec_len), ...
        'rst', 1, ...
        'Position', [600 92 650 118]);

    reuse_block(blk, 'const0', 'xbsIndex_r4/Constant', ...
        'const', '0', ...
        'arith_type', 'Unsigned', ...
        'n_bits', num2str(bram_n_bits), ...
        'bin_pt', '0', ...
        'explicit_period', 1, ...
        'Position', [675 117 700 133]);

    reuse_block(blk, 'const1', 'xbsIndex_r4/Constant', ...
        'const', '0', ...
        'arith_type', 'Boolean', ...
        'explicit_period', 1, ...
        'Position', [675 138 700 152]);

    reuse_block(blk, 'const2', 'xbsIndex_r4/Constant', ...
        'const', '0', ...
        'arith_type', 'Unsigned', ...
        'n_bits', num2str(bram_n_bits), ...
        'bin_pt', '0', ...
        'explicit_period', 1, ...
        'Position', [675 192 700 208]);

    reuse_block(blk, 'const3', 'xbsIndex_r4/Constant', ...
        'const', '0', ...
        'arith_type', 'Boolean', ...
        'explicit_period', 1, ...
        'Position', [675 213 700 227]);

    reuse_block(blk, 'bram_re', 'xps_library/Shared_BRAM', ...
        'arith_type', 'Signed', ...
        'addr_width', num2str(bram_addr_width), ...
        'data_width', bram_n_bits_popup-1, ...
        'data_bin_pt', num2str(bram_bin_pt), ...
        'Position', [725 97 800 153]);

    reuse_block(blk, 'bram_im', 'xps_library/Shared_BRAM', ...
        'arith_type', 'Signed', ...
        'addr_width', num2str(bram_addr_width), ...
        'data_width', bram_n_bits_popup-1, ...
        'data_bin_pt', num2str(bram_bin_pt), ...
        'Position', [725 172 800 228]);

    reuse_block(blk, 'pipeline', 'casper_library_delays/pipeline', ...
        'latency', '1', ...
        'Position', [730 304 795 326]);
            
    reuse_block(blk, 'c_to_ri1', 'casper_library_misc/c_to_ri', ...
        'n_bits', num2str(din_n_bits), ...
        'bin_pt', num2str(din_bin_pt), ...
        'Position', [835 237 860 388]);
        
    reuse_block(blk, 'cmult_dsp48e', 'casper_library_multipliers/cmult_dsp48e', ...
        'n_bits_a', '25', ...
        'bin_pt_a', num2str(25-(bram_n_bits-bram_bin_pt)), ...
        'n_bits_b', num2str(din_n_bits), ...
        'bin_pt_b', num2str(din_bin_pt), ...
        'conjugated', 0, ...
        'full_precision', 0, ...
        'n_bits_c', num2str(dout_n_bits), ...
        'bin_pt_c', num2str(dout_bin_pt), ...
        'quantization', quantization-1, ...
        'overflow', overflow-1, ...
        'Position', [915 90 980 385]);
                
    reuse_block(blk, 'ri_to_c', 'casper_library_misc/ri_to_c', ...
        'Position', [1020 93 1055 382]);

    reuse_block(blk, 'dout', 'simulink/Sinks/Out1', ...
        'Port', '1', ...
        'Position', [1085 233 1115 247]);
    
    quant_str = {'Truncate', 'Round (unbiased: +/- Inf)'};
    of_str = {'Wrap', 'Saturate', 'Flag as error'};
    annotation = sprintf('%d_%d * %d_%d ==> %d_%d\n%s, %s', ...
        din_n_bits, din_bin_pt, bram_n_bits, bram_bin_pt, dout_n_bits, dout_bin_pt,...
        cell2mat(quant_str(quantization)), cell2mat(of_str(overflow)));
    set_param(blk, 'AttributesFormatString', annotation);
        
    % add lines
    add_line(blk, 'sync/1', 'Counter/1');
    add_line(blk, 'din/1', 'pipeline/1');
    add_line(blk, 'Counter/1', 'bram_re/1');
    add_line(blk, 'Counter/1', 'bram_im/1');
    add_line(blk, 'const0/1', 'bram_re/2');
    add_line(blk, 'const1/1', 'bram_re/3');
    add_line(blk, 'const2/1', 'bram_im/2');
    add_line(blk, 'const3/1', 'bram_im/3');
    add_line(blk, 'bram_re/1', 'cmult_dsp48e/1');
    add_line(blk, 'bram_im/1', 'cmult_dsp48e/2');
    add_line(blk, 'pipeline/1', 'c_to_ri1/1');
    add_line(blk, 'c_to_ri1/1', 'cmult_dsp48e/3');
    add_line(blk, 'c_to_ri1/2', 'cmult_dsp48e/4');
    add_line(blk, 'cmult_dsp48e/1', 'ri_to_c/1');
    add_line(blk, 'cmult_dsp48e/2', 'ri_to_c/2');
    add_line(blk, 'ri_to_c/1', 'dout/1');

    clean_blocks(blk)

    save_state(blk, varargin{:})