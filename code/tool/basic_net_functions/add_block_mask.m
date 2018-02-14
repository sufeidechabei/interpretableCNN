function net = add_block_mask(net,lossWeight, opts, id, h, w, in, out, stride, pad,partRate,textureRate,mag)
alphaInit=2.0; %1.5; %2.0;

partNum=round(partRate*in);
textureNum=round((textureRate+partRate)*in)-partNum;
filterType=zeros(in,1);
filterType(1:partNum)=1;
filterType((1:textureNum)+partNum)=2;

info = our_vl_simplenn_display(net) ;
fc = (h == info.dataSize(1,end) && w == info.dataSize(2,end)) ;
if fc
  name = 'fc' ;
else
  name = 'conv' ;
end
convOpts = {'CudnnWorkspaceLimit', opts.cudnnWorkspaceLimit} ;
dataH=info.dataSize(1,end);
dataW=info.dataSize(2,end);
posTemp_x=single(repmat(linspace(-1,1,dataH)',[1,dataW,in]));
posTemp_y=single(repmat(linspace(-1,1,dataW),[dataH,1,in]));
net.layers{end+1} = struct('type', 'conv_mask', 'name', sprintf('%s%s', name, id), ...
                           'weights', {{init_weight(opts, h, w, in, out, 'single'), ...
                             ones(out, 1, 'single')*opts.initBias,ones(in, 1, 'single')*alphaInit}}, ...
                           'stride', stride, ...
                           'pad', pad, ...
                           'dilate', 1, ...
                           'learningRate', [1 2 0.05], ...
                           'weightDecay', [opts.weightDecay 0 0],'posTemp',{{posTemp_x,posTemp_y}},'lossWeight',lossWeight,'mu_x',[],'mu_y',[],'sqrtvar',[],'strength',[],'sliceMag',[],'iter',[],'filter',filterType,'mag',mag,...
                           'opts', {convOpts}) ;
if opts.batchNormalization
  net.layers{end+1} = struct('type', 'bnorm', 'name', sprintf('bn%s',id), ...
                             'weights', {{ones(out, 1, 'single'), zeros(out, 1, 'single'), ...
                               zeros(out, 2, 'single')}}, ...
                             'epsilon', 1e-4, ...
                             'learningRate', [2 1 0.1], ...
                             'weightDecay', [0 0]) ;
end
net.layers{end+1} = struct('type', 'relu', 'name', sprintf('relu%s',id)) ;

end