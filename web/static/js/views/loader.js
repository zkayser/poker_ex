import MainView from './main-view';
import RoomIndexView from './room/index';
import PlayerShowView from './player/show';

const views = {
  RoomIndexView,
  PlayerShowView,
};

export default function loadView(viewName) {
  return views[viewName] || MainView;
}