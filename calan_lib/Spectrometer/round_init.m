function round_init(blk, varargin)
%este bloque sirve para ...
defaults = {'arith_type', 'Signed (2''s comp)', ...
    	    'n_bits', 64, ...
            'bin_pt', 18,...
            'overflow', 'Wrap'};
%'data_type', 'Boolean', ...
%            'quantization', 'Truncate', ...

check_mask_type(blk, 'round');

if same_state(blk, 'defaults', defaults, varargin{:}), return, end
clog('round_init post same_state', 'trace');
munge_block(blk, varargin{:});

%data_type          = get_var('data_type', 'defaults', defaults, varargin{:});
arith_type         = get_var('arith_type', 'defaults', defaults, varargin{:});
n_bits             = get_var('n_bits', 'defaults', defaults, varargin{:});
bin_pt             = get_var('bin_pt', 'defaults', defaults, varargin{:});
%quantization       = get_var('quantization', 'defaults', defaults, varargin{:});
overflow           = get_var('overflow', 'defaults', defaults, varargin{:});

delete_lines(blk);

if n_bits  == 0,
    clean_blocks(blk);
    save_state(blk, 'defaults', defaults, varargin{:});  
    return; 
end


    % Inputs ports
reuse_block(blk, 'din', 'built-in/inport', 'Port', '1', ...
    'Position', [20    23    50    37]);

reuse_block(blk, 'scale', 'built-in/inport', 'Port', '2', ...
    'Position', [20    78    50    92]);

    % Multiplier

reuse_block(blk, 'Mult', 'xbsIndex_r4/Mult', ...
    'ShowName', 'off', ... 
    'precision', 'Full', ...
    'latency', '8', ...
    'opt', 'Speed', ...
    'use_embedded', 'on', ...
    'optimum_pipeline', 'on', ...
    'Position', [235    20   280    60]);

    % Convert

reuse_block(blk, 'Convert', 'xbsIndex_r4/Convert', ...
    'ShowName', 'off', ...
    'gui_display_data_type', 'Floating-point', ...
    'arith_type', arith_type, ...
    'n_bits', num2str(n_bits), ...
    'bin_pt', num2str(bin_pt), ...
    'quantization', 'Round  (unbiased: Even Values)', ...
    'overflow', overflow-1, ...
    'latency', '4', ...
    'pipeline', 'on', ...
    'en', 'off', ...
    'Position', [345    20   395    60]);


    % output ports
reuse_block(blk, 'dout', 'built-in/outport', 'Port', '1', ...
    'Position', [460    33   490    47]);

%add lines between blocks

    % add lines in the In-port path

add_line(blk,'din/1', 'Mult/1',     'autorouting', 'on');
add_line(blk,'scale/1', 'Mult/2',   'autorouting', 'on');

    % add lines in the Multiplier path

add_line(blk,'Mult/1', 'Convert/1', 'autorouting', 'on');

    % add lines in the Convert path

add_line(blk,'Convert/1', 'dout/1', 'autorouting', 'on');


clean_blocks(blk);

save_state(blk, 'defaults', defaults, varargin{:});
end
