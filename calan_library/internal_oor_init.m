function internal_oor_init (blk, varargin)
% Usage: internal_oor_init (gcb, 'var')
% Detects if any of the inputs are in the out of range limit (i.e. the input 
% is equal to the maximum or minimum value given the data type). If out of
% range is detected, the block hold a 1 in the output until is reseted. It 
% assumes signed typed inputs.
%
% Valid 'var' names are:
% n_inputs = Number of inputs
% n_bits = number of bits of inputs
% bin_pt = binary point

    if same_state(blk, varargin{:}), return, end
    munge_block(blk, varargin{:});

    n_inputs = get_var('n_inputs', varargin{:});
    n_bits   = get_var('n_bits',   varargin{:});
    bin_pt   = get_var('bin_pt',   varargin{:});

    delete_lines(blk);

    if (n_bits < bin_pt),
        errordlg('Number of bits for output must be greater than binary point position.'); return; end

    if (n_inputs < 1),
        errordlg('Number of must b egreater than 1.'); return; end

    in_min = -2^(n_bits-bin_pt-1);
    in_max =  2^(n_bits-bin_pt-1) - 2^-bin_pt; 

    % individual block comparison
    diff_y = 125;
    for i=1:n_inputs
        reuse_block(blk, strcat('In', num2str(i)), 'simulink/Sources/In1', ...
            'Port', num2str(i), ...
            'Position', [0 diff_y*i 30 diff_y*i+20]);

        reuse_block(blk, strcat('max_', num2str(i)), 'xbsIndex_r4/Constant', ...
            'arith_type', 'Signed', ...
            'const', num2str(in_max), ...
            'n_bits', num2str(n_bits), ...
            'bin_pt', num2str(bin_pt), ...
            'explicit_period', 'on', ...
            'period', '1', ...
            'Position', [75 diff_y*i+11   75+65 diff_y*i+11+22]);

        reuse_block(blk, strcat('min_', num2str(i)), 'xbsIndex_r4/Constant', ...
            'arith_type', 'Signed', ...
            'const', num2str(in_min), ...
            'n_bits', num2str(n_bits), ...
            'bin_pt', num2str(bin_pt), ...
            'explicit_period', 'on', ...
            'period', '1', ...
            'Position', [75 diff_y*i+61   75+65 diff_y*i+61+22]);

        reuse_block(blk, strcat('geq_', num2str(i)), 'xbsIndex_r4/Relational', ...
            'mode', 'a>=b', ...
            'latency', '1', ...
            'Position', [165 diff_y*i-1 165+55 diff_y*i-1+31]);

        reuse_block(blk, strcat('leq_', num2str(i)), 'xbsIndex_r4/Relational', ...
            'mode', 'a<=b', ...
            'latency', '1', ...
            'Position', [165 diff_y*i+49 165+55 diff_y*i+49+31]);

        reuse_block(blk, strcat('or_', num2str(i)), 'xbsIndex_r4/Logical', ...
            'logical_function', 'OR', ...
            'inputs', '2', ...
            'Position', [245 diff_y*i-10 245+30 diff_y*i-10+104]);
        
        add_line(blk, strcat('In', num2str(i), '/1'), strcat('geq_', num2str(i), '/1'));
        add_line(blk, strcat('max_', num2str(i), '/1'), strcat('geq_', num2str(i), '/2'));
        add_line(blk, strcat('In', num2str(i), '/1'), strcat('leq_', num2str(i), '/1'));
        add_line(blk, strcat('min_', num2str(i), '/1'), strcat('leq_', num2str(i), '/2'));
        add_line(blk, strcat('geq_', num2str(i), '/1'), strcat('or_', num2str(i), '/1'));
        add_line(blk, strcat('leq_', num2str(i), '/1'), strcat('or_', num2str(i), '/2'));
    end
    
    % final or and hold output
    reuse_block(blk, 'final_or', 'xbsIndex_r4/Logical', ...
        'logical_function', 'OR', ...
        'inputs', num2str(n_inputs), ...
        'Position', [300 diff_y*1-10 300+30 diff_y*n_inputs-10+104]);
    
    reuse_block(blk, 'reg', 'xbsIndex/Register', ...
        'rst', 'on', ...
        'en', 'on', ...
        'Position', [450 diff_y*(n_inputs+1)/2+52-28-10 450+60 diff_y*(n_inputs+1)/2+52+28-10]);
        
    reuse_block(blk, strcat('rst'), 'simulink/Sources/In1', ...
            'Port', num2str(n_inputs+1), ...
            'Position', [390 diff_y*(n_inputs+1)/2+52-10-10 390+30 diff_y*(n_inputs+1)/2+52+10-10]);
        
    reuse_block(blk, strcat('out_of_range'), 'simulink/Sinks/Out1', ...
            'Port', '1', ...
            'Position', [540 diff_y*(n_inputs+1)/2+52-10-10 540+30 diff_y*(n_inputs+1)/2+52+10-10]);
        
    for i=1:n_inputs
        add_line(blk, strcat('or_', num2str(i), '/1'), strcat('final_or/', num2str(i)));
    end
    add_line(blk, 'final_or/1', 'reg/1');
    add_line(blk, 'final_or/1', 'reg/3');
    add_line(blk, 'rst/1', 'reg/2');
    add_line(blk, 'reg/1', 'out_of_range/1');
    
    clean_blocks(blk);
    save_state(blk, varargin{:});

end

